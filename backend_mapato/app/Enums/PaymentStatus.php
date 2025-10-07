<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case PENDING = 'pending';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';
    case FAILED = 'failed';
    case REFUNDED = 'refunded';

    /**
     * Get the display name for the status
     */
    public function label(): string
    {
        return match($this) {
            self::PENDING => 'Inasubiri',
            self::COMPLETED => 'Imekamilika',
            self::CANCELLED => 'Imeghairiwa',
            self::FAILED => 'Imeshindwa',
            self::REFUNDED => 'Imerudishwa',
        };
    }

    /**
     * Get the color for the status
     */
    public function color(): string
    {
        return match($this) {
            self::PENDING => 'orange',
            self::COMPLETED => 'green',
            self::CANCELLED => 'red',
            self::FAILED => 'red',
            self::REFUNDED => 'blue',
        };
    }

    /**
     * Check if the status is final (cannot be changed)
     */
    public function isFinal(): bool
    {
        return in_array($this, [
            self::COMPLETED,
            self::CANCELLED,
            self::FAILED,
            self::REFUNDED,
        ]);
    }

    /**
     * Get all status values
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    /**
     * Get all status labels
     */
    public static function labels(): array
    {
        $labels = [];
        foreach (self::cases() as $case) {
            $labels[$case->value] = $case->label();
        }
        return $labels;
    }
}