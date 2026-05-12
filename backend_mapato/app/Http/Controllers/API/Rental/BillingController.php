<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Services\Rental\RentalService;
use App\Services\SmsService;
use App\Models\Rental\RentBill;
use App\Models\Rental\RentalPayment;
use App\Models\Rental\RentalReceipt;
use App\Models\Rental\RentalAgreement;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Carbon\Carbon;

class BillingController extends Controller
{
    protected $rentalService;

    public function __construct(RentalService $rentalService)
    {
        $this->rentalService = $rentalService;
    }

    /**
     * Get all bills (for landlord or tenant).
     */
    public function getBills(Request $request)
    {
        $user = $request->user();
        
        if ($user->isLandlord() || $user->role === 'admin') {
            $bills = RentBill::whereHas('agreement.house.property', function($query) use ($user) {
                $query->where('owner_id', $user->id);
            })->with('agreement.tenant', 'agreement.house.property')->get();
        } elseif ($user->role === 'tenant') {
            $bills = RentBill::whereHas('agreement', function($query) use ($user) {
                $query->where('tenant_id', $user->id);
            })->with('agreement.house.property')->get();
        } else {
            // Caretaker - show all bills for assigned properties
            $bills = RentBill::whereHas('agreement.house.property', function($query) use ($user) {
                $query->where('owner_id', $user->id);
            })->with('agreement.tenant', 'agreement.house.property')->get();
        }

        return ResponseHelper::success($bills);
    }

    /**
     * Get all payments.
     */
    public function getPayments(Request $request)
    {
        $user = $request->user();
        
        $payments = RentalPayment::whereHas('bill.agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->with('bill.agreement.house', 'tenant', 'collector', 'receipt')
        ->orderBy('payment_date', 'desc')
        ->get();
        
        return ResponseHelper::success($payments);
    }

    /**
     * Get all receipts.
     */
    public function getReceipts(Request $request)
    {
        $user = $request->user();
        
        $receipts = RentalReceipt::whereHas('payment.bill.agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->with('payment.tenant', 'payment.bill.agreement.house')
        ->orderBy('created_at', 'desc')
        ->get();
        
        return ResponseHelper::success($receipts);
    }

    /**
     * Get single receipt details.
     */
    public function getReceipt(Request $request, $id)
    {
        $receipt = RentalReceipt::with('payment.tenant', 'payment.bill.agreement.house.property', 'payment.collector')
            ->findOrFail($id);
        
        return ResponseHelper::success($receipt);
    }

    /**
     * Record a new payment.
     */
    public function recordPayment(Request $request)
    {
        $request->validate([
            'bill_id' => 'required|exists:rental_bills,id',
            'amount_paid' => 'required|numeric|min:1',
            'payment_method' => 'required|string|in:cash,bank_transfer,m-pesa,airtel_money,tigo_pesa',
            'transaction_reference' => 'nullable|string',
            'payment_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        try {
            $data = $request->all();
            $data['collector_id'] = $request->user()->id;
            
            $payment = $this->rentalService->recordPayment($data);
            $payment->load('bill.agreement.house.property', 'tenant', 'receipt');
            
            // Send SMS confirmation
            SmsService::sendPaymentReceipt(
                $payment->tenant->phone_number,
                $payment->amount_paid,
                $payment->receipt->receipt_number,
                $payment->bill->balance
            );
            
            return ResponseHelper::success($payment, 'Payment recorded successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /**
     * Get dashboard statistics.
     */
    public function getDashboard(Request $request)
    {
        $user = $request->user();
        
        // Total properties
        $totalProperties = \App\Models\Rental\Property::where('owner_id', $user->id)->count();
        
        // Total houses
        $totalHouses = \App\Models\Rental\House::whereHas('property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->count();
        
        // Occupied houses
        $occupiedHouses = \App\Models\Rental\House::whereHas('property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->where('status', 'occupied')->count();
        
        // Active tenants
        $activeTenants = RentalAgreement::whereHas('house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->where('status', 'active')->count();
        
        // Monthly revenue this month
        $thisMonth = Carbon::now()->format('m-Y');
        $monthlyRevenue = RentalPayment::whereHas('bill.agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->whereHas('bill', function($query) use ($thisMonth) {
            $query->where('month_year', $thisMonth);
        })->sum('amount_paid');
        
        // Pending bills (unpaid + partial)
        $pendingBills = RentBill::whereHas('agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->whereIn('status', ['unpaid', 'partial'])->count();
        
        // Overdue bills
        $overdueBills = RentBill::whereHas('agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->where('status', 'overdue')->count();
        
        // Total arrears amount
        $totalArrears = RentBill::whereHas('agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->whereIn('status', ['unpaid', 'partial', 'overdue'])->sum('balance');
        
        // Recent payments
        $recentPayments = RentalPayment::whereHas('bill.agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->with('tenant', 'bill.agreement.house')->orderBy('payment_date', 'desc')->limit(5)->get();
        
        return ResponseHelper::success([
            'total_properties' => $totalProperties,
            'total_houses' => $totalHouses,
            'occupied_houses' => $occupiedHouses,
            'vacant_houses' => $totalHouses - $occupiedHouses,
            'active_tenants' => $activeTenants,
            'monthly_revenue' => $monthlyRevenue,
            'pending_bills' => $pendingBills,
            'overdue_bills' => $overdueBills,
            'total_arrears' => $totalArrears,
            'recent_payments' => $recentPayments,
        ]);
    }

    /**
     * Get arrears report.
     */
    public function getArrears(Request $request)
    {
        $user = $request->user();
        
        $arrears = RentBill::whereHas('agreement.house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->whereIn('status', ['unpaid', 'partial', 'overdue'])
        ->with('agreement.tenant.user', 'agreement.house.property')
        ->orderBy('due_date', 'asc')
        ->get();
        
        // Group by status
        $byStatus = [
            'overdue' => $arrears->where('status', 'overdue'),
            'unpaid' => $arrears->where('status', 'unpaid'),
            'partial' => $arrears->where('status', 'partial'),
        ];
        
        return ResponseHelper::success([
            'arrears' => $arrears,
            'by_status' => $byStatus,
            'total_arrears' => $arrears->sum('balance'),
            'count' => $arrears->count(),
        ]);
    }

    /**
     * Get revenue report.
     */
    public function getRevenue(Request $request)
    {
        $user = $request->user();
        $period = $request->get('period', 'monthly'); // monthly or yearly
        
        if ($period === 'yearly') {
            // Last 12 months
            $payments = RentalPayment::whereHas('bill.agreement.house.property', function($query) use ($user) {
                $query->where('owner_id', $user->id);
            })->where('payment_date', '>=', now()->subMonths(12))
            ->get();
            
            // Group by month
            $revenue = $payments->groupBy(function($p) {
                return $p->payment_date->format('m-Y');
            })->map(function($group) {
                return $group->sum('amount_paid');
            });
        } else {
            // Last 30 days
            $payments = RentalPayment::whereHas('bill.agreement.house.property', function($query) use ($user) {
                $query->where('owner_id', $user->id);
            })->where('payment_date', '>=', now()->subDays(30))
            ->get();
            
            // Group by date
            $revenue = $payments->groupBy(function($p) {
                return $p->payment_date->format('d-m');
            })->map(function($group) {
                return $group->sum('amount_paid');
            });
        }
        
        return ResponseHelper::success([
            'period' => $period,
            'revenue' => $revenue,
            'total' => $payments->sum('amount_paid'),
        ]);
    }
}