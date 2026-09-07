<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

class ExpenseController extends Controller
{
    private const CATEGORIES = [
        'rent', 'salaries', 'transport', 'utilities',
        'supplies', 'maintenance', 'marketing', 'other',
    ];

    /** GET /inventory/expenses */
    public function index(Request $request)
    {
        [$from, $to] = $this->dateRange($request);

        $rows = DB::table('inventory_expenses as e')
            ->leftJoin('users as u', 'u.id', '=', 'e.created_by')
            ->whereBetween('e.expense_date', [$from, $to])
            ->orderByDesc('e.expense_date')
            ->orderByDesc('e.id')
            ->select('e.*', 'u.name as created_by_name')
            ->get();

        return response()->json(['data' => $rows]);
    }

    /** POST /inventory/expenses */
    public function store(Request $request)
    {
        $data = $request->validate([
            'category'     => 'required|string|max:60',
            'description'  => 'required|string|max:255',
            'amount'       => 'required|numeric|min:0.01',
            'expense_date' => 'required|date',
        ]);

        $id = DB::table('inventory_expenses')->insertGetId([
            'category'     => $data['category'],
            'description'  => $data['description'],
            'amount'       => $data['amount'],
            'expense_date' => $data['expense_date'],
            'created_by'   => optional($request->user())->id,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        return response()->json([
            'message' => 'Expense recorded',
            'data'    => DB::table('inventory_expenses')->find($id),
        ], 201);
    }

    /** PUT /inventory/expenses/{id} */
    public function update(Request $request, int $id)
    {
        $expense = DB::table('inventory_expenses')->find($id);
        if (! $expense) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'category'     => 'sometimes|string|max:60',
            'description'  => 'sometimes|string|max:255',
            'amount'       => 'sometimes|numeric|min:0.01',
            'expense_date' => 'sometimes|date',
        ]);

        DB::table('inventory_expenses')->where('id', $id)->update(
            array_merge($data, ['updated_at' => now()])
        );

        return response()->json(['data' => DB::table('inventory_expenses')->find($id)]);
    }

    /** DELETE /inventory/expenses/{id} */
    public function destroy(int $id)
    {
        DB::table('inventory_expenses')->where('id', $id)->delete();
        return response()->json(['message' => 'Deleted']);
    }

    /**
     * GET /inventory/expenses/summary
     * Returns per-category totals AND revenue-vs-expense for the period.
     */
    public function summary(Request $request)
    {
        [$from, $to] = $this->dateRange($request);

        // Expenses by category
        $byCategory = DB::table('inventory_expenses')
            ->whereBetween('expense_date', [$from, $to])
            ->groupBy('category')
            ->orderByRaw('SUM(amount) DESC')
            ->select('category', DB::raw('SUM(amount) as total'), DB::raw('COUNT(*) as count'))
            ->get();

        $totalExpenses = $byCategory->sum('total');

        // Revenue = sum of paid_total from sales in range
        $revenue = (float) DB::table('inventory_sales')
            ->whereBetween(DB::raw('DATE(created_at)'), [$from, $to])
            ->whereNotIn('payment_status', ['cancelled'])
            ->sum('paid_total');

        // COGS = sum of (unit_cost_snapshot × quantity) from sale items in range
        $cogs = (float) DB::table('inventory_sale_items as si')
            ->join('inventory_sales as s', 's.id', '=', 'si.sale_id')
            ->whereBetween(DB::raw('DATE(s.created_at)'), [$from, $to])
            ->whereNotIn('s.payment_status', ['cancelled'])
            ->selectRaw('SUM(si.unit_cost_snapshot * si.quantity) as cogs')
            ->value('cogs') ?? 0;

        $grossProfit    = $revenue - $cogs;
        $netProfit      = $grossProfit - (float) $totalExpenses;
        $expenseRatio   = $revenue > 0 ? round(($totalExpenses / $revenue) * 100, 1) : 0;

        return response()->json([
            'data' => [
                'from'           => $from,
                'to'             => $to,
                'revenue'        => round($revenue, 2),
                'cogs'           => round($cogs, 2),
                'gross_profit'   => round($grossProfit, 2),
                'total_expenses' => round((float) $totalExpenses, 2),
                'net_profit'     => round($netProfit, 2),
                'expense_ratio'  => $expenseRatio,   // % of revenue
                'by_category'    => $byCategory,
            ],
        ]);
    }

    /** GET /inventory/expenses/categories */
    public function categories()
    {
        return response()->json(['data' => self::CATEGORIES]);
    }

    private function dateRange(Request $request): array
    {
        $period = $request->query('period', 'today');
        $from   = $request->query('from');
        $to     = $request->query('to');

        if ($from && $to) {
            return [$from, $to];
        }

        $now = now();
        return match ($period) {
            'week'  => [$now->copy()->startOfWeek()->toDateString(), $now->toDateString()],
            'month' => [$now->copy()->startOfMonth()->toDateString(), $now->toDateString()],
            'year'  => [$now->copy()->startOfYear()->toDateString(), $now->toDateString()],
            default => [$now->toDateString(), $now->toDateString()], // today
        };
    }
}
