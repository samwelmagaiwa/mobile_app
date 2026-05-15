<?php

namespace App\Services\Rental;

use App\Models\User;
use App\Models\Rental\Property;
use App\Models\Rental\House;
use App\Models\Rental\TenantProfile;
use App\Models\Rental\RentalAgreement;
use App\Models\Rental\RentBill;
use App\Models\Rental\RentalPayment;
use App\Models\Rental\RentalReceipt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;

class RentalService
{
    /**
     * Onboard a new tenant and assign them to a house.
     */
    public function onboardTenant(array $data)
    {
        return DB::transaction(function () use ($data) {
            // 1. Create User account if not exists
            $user = User::where('email', $data['email'])->orWhere('phone_number', $data['phone_number'])->first();

            if (!$user) {
                $user = User::create([
                    'name' => $data['name'],
                    'email' => $data['email'],
                    'phone_number' => $data['phone_number'],
                    'password' => bcrypt($data['password'] ?? 'tenant123'),
                    'role' => 'tenant',
                    'service_type' => 'rental',
                    'is_active' => true,
                ]);
            }

            // 2. Create Tenant Profile
            TenantProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'gender' => $data['gender'] ?? null,
                    'dob' => $data['dob'] ?? null,
                    'id_number' => $data['nida'] ?? ($data['id_details']['number'] ?? ($data['id_number'] ?? null)),
                    'id_state' => $data['id_details']['state'] ?? null,
                    'id_expiration' => $data['id_details']['expiration'] ?? null,
                    'occupation' => $data['employment']['title'] ?? ($data['occupation'] ?? null),
                    'employment' => $data['employment'] ?? null,
                    'emergency_contact_name' => $data['emergency_contact']['name'] ?? ($data['emergency_contact_name'] ?? null),
                    'emergency_contact_phone' => $data['emergency_contact']['phone'] ?? ($data['emergency_contact_phone'] ?? null),
                    'history' => $data['history'] ?? null,
                    'occupants' => $data['occupants'] ?? null,
                    'pets' => $data['pets'] ?? null,
                    'photo_url' => $data['photo_url'] ?? null,
                    'notes' => $data['notes'] ?? null,
                ]
            );

            // 3. Create Rental Agreement
            $agreement = RentalAgreement::create([
                'tenant_id' => $user->id,
                'house_id' => $data['house_id'],
                'start_date' => $data['start_date'] ?? now(),
                'rent_cycle' => $data['rent_cycle'] ?? 'monthly',
                'rent_amount' => $data['rent_amount'],
                'deposit_paid' => $data['deposit_paid'] ?? 0,
                'status' => 'active',
            ]);

            // 4. Update House status
            $house = House::find($data['house_id']);
            $house->update([
                'status' => 'occupied',
                'current_tenant_id' => $user->id,
            ]);

            // 5. Generate first bill
            $this->generateBillForAgreement($agreement, Carbon::parse($agreement->start_date));

            return [
                'user' => $user,
                'agreement' => $agreement,
            ];
        });
    }

    /**
     * Generate a rent bill for a specific agreement and period.
     */
    public function generateBillForAgreement(RentalAgreement $agreement, Carbon $date)
    {
        $monthYear = $date->format('m-Y');

        // Avoid duplicate bills for same period
        $existing = RentBill::where('agreement_id', $agreement->id)
            ->where('month_year', $monthYear)
            ->first();
        if ($existing)
            return $existing;

        return RentBill::create([
            'agreement_id' => $agreement->id,
            'month_year' => $monthYear,
            'amount_due' => $agreement->rent_amount,
            'balance' => $agreement->rent_amount,
            'due_date' => $date->copy()->startOfMonth()->addDays(5), // Default due date 5th of month
            'status' => 'unpaid',
        ]);
    }

    /**
     * Record a payment against a bill.
     */
    public function recordPayment(array $data)
    {
        return DB::transaction(function () use ($data) {
            $bill = RentBill::findOrFail($data['bill_id']);
            $amountPaid = $data['amount_paid'];

            // Validate: prevent overpayment
            if ($amountPaid > $bill->balance) {
                throw new \Exception('Cannot pay more than the balance. Maximum allowed: ' . $bill->balance);
            }

            // 1. Create Payment record
            $payment = RentalPayment::create([
                'bill_id' => $bill->id,
                'tenant_id' => $bill->agreement->tenant_id,
                'amount_paid' => $amountPaid,
                'payment_date' => $data['payment_date'] ?? now(),
                'payment_method' => $data['payment_method'],
                'transaction_reference' => $data['transaction_reference'] ?? null,
                'collector_id' => $data['collector_id'],
                'notes' => $data['notes'] ?? null,
            ]);

            // 2. Update Bill balance and status
            $newBalance = $bill->balance - $amountPaid;
            $status = 'partial';
            if ($newBalance <= 0) {
                $status = 'paid';
                $newBalance = 0;
            }

            $bill->update([
                'balance' => $newBalance,
                'status' => $status,
            ]);

            // 3. Generate Receipt
            $receipt = $this->generateReceipt($payment);

            // 4. Send SMS Notification
            \App\Services\SmsService::sendPaymentReceipt(
                $payment->tenant->phone_number,
                $payment->amount_paid,
                $receipt->receipt_number,
                $bill->balance
            );

            return $payment;
        });
    }

    /**
     * Generate a digital receipt for a payment.
     */
    public function generateReceipt(RentalPayment $payment)
    {
        $payment->load('bill.agreement.house.property', 'tenant', 'collector');

        $receiptNumber = 'RCP-' . strtoupper(Str::random(8));

        $details = [
            'receipt_number' => $receiptNumber,
            'date' => $payment->payment_date->format('Y-m-d'),
            'tenant_name' => $payment->tenant->name,
            'house_number' => $payment->bill->agreement->house->house_number,
            'property_name' => $payment->bill->agreement->house->property->name,
            'period' => $payment->bill->month_year,
            'amount_paid' => $payment->amount_paid,
            'balance_remaining' => $payment->bill->balance,
            'payment_method' => $payment->payment_method,
            'collector_name' => $payment->collector->name,
        ];

        return RentalReceipt::create([
            'payment_id' => $payment->id,
            'receipt_number' => $receiptNumber,
            'details' => $details,
        ]);
    }

    /**
     * Generate bills for all active agreements for the current/next month.
     */
    public function generateMonthlyBills()
    {
        $agreements = RentalAgreement::where('status', 'active')->get();
        $count = 0;
        $date = now()->addDays(7); // Look ahead 7 days to generate next month's bill early

        foreach ($agreements as $agreement) {
            $bill = $this->generateBillForAgreement($agreement, $date);
            if ($bill->wasRecentlyCreated)
                $count++;
        }

        return $count;
    }

    /**
     * Check for unpaid bills past due date and mark them as overdue.
     */
    public function processOverdueBills()
    {
        $bills = RentBill::where('status', '!=', 'paid')
            ->where('status', '!=', 'overdue')
            ->where('due_date', '<', now())
            ->with('agreement.tenant', 'agreement.house')
            ->get();

        foreach ($bills as $bill) {
            $bill->update(['status' => 'overdue']);

            // Trigger SMS notification
            \App\Services\SmsService::sendOverdueAlert(
                $bill->agreement->tenant->phone_number,
                $bill->agreement->house->house_number,
                $bill->balance
            );
        }

        return $bills->count();
    }
}
