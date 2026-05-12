<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class SmsService
{
    /**
     * Send an SMS notification.
     * In MVP, we just log the message.
     */
    public static function send($phone, $message)
    {
        Log::info("SMS SENT to {$phone}: {$message}");
        
        // Integration with a real provider (e.g., Beem, Twilio) would go here
        return true;
    }

    public static function sendPaymentReceipt($phone, $amount, $receiptNo, $balance)
    {
        $message = "Dear Customer, payment of TZS " . number_format($amount) . " received. Receipt No: {$receiptNo}. Remaining Balance: TZS " . number_format($balance) . ". Thank you.";
        return self::send($phone, $message);
    }

    public static function sendRentReminder($phone, $houseNo, $amount, $dueDate)
    {
        $message = "Reminder: Your rent for House {$houseNo} (TZS " . number_format($amount) . ") is due on {$dueDate}. Please pay on time to avoid penalties.";
        return self::send($phone, $message);
    }

    public static function sendOverdueAlert($phone, $houseNo, $balance)
    {
        $message = "URGENT: Your rent for House {$houseNo} is OVERDUE. Outstanding balance: TZS " . number_format($balance) . ". Please settle immediately.";
        return self::send($phone, $message);
    }

    public static function sendTenantWelcome($tenant, $house)
    {
        $message = "Welcome to {$house->property->name}! You have been registered " .
            "for House {$house->house_number}. Your monthly rent is TZS " . 
            number_format($house->rent_amount) . ". Thank you.";
        return self::send($tenant->phone_number, $message);
    }
}
