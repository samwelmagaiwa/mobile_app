<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * GET /api/inventory/products: 20 a page by default (what the product list relies on), and an
 * optional page size so the profit-by-product screen can load the whole catalogue in few calls.
 */
class ProductListPagingTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->create(['role' => 'admin', 'is_active' => true]);
        $this->admin->services()->create(['service_type' => 'inventory']);

        for ($i = 1; $i <= 130; $i++) {
            DB::table('inventory_products')->insert([
                'name' => "Product {$i}", 'sku' => "SKU-{$i}", 'cost_price' => 100, 'selling_price' => 150,
                'unit' => 'pcs', 'quantity' => $i, 'min_stock' => 1, 'status' => 'active',
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function list(string $query = ''): array
    {
        $token = $this->admin->createToken('t')->plainTextToken;
        $this->app['auth']->forgetGuards();

        return $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/inventory/products' . $query)->assertOk()->json();
    }

    public function test_the_default_page_is_still_twenty(): void
    {
        $body = $this->list();

        $this->assertCount(20, $body['data']);
        $this->assertSame(20, $body['meta']['per_page']);
        $this->assertSame(130, $body['meta']['total']);
        $this->assertSame(7, $body['meta']['last_page']);
    }

    public function test_a_client_can_ask_for_a_bigger_page(): void
    {
        $body = $this->list('?per_page=100');

        $this->assertCount(100, $body['data']);
        $this->assertSame(2, $body['meta']['last_page']);
        $this->assertCount(30, $this->list('?per_page=100&page=2')['data']);
    }

    public function test_the_page_size_is_capped_and_junk_is_ignored(): void
    {
        $this->assertCount(100, $this->list('?per_page=100000')['data']);
        $this->assertCount(20, $this->list('?per_page=abc')['data']);
        $this->assertCount(20, $this->list('?per_page=-5')['data']);
    }

    public function test_paging_through_everything_returns_every_product_exactly_once(): void
    {
        $ids = [];
        $page = 1;
        do {
            $body = $this->list("?per_page=100&page={$page}");
            $ids = array_merge($ids, array_column($body['data'], 'id'));
            $page++;
        } while ($page <= $body['meta']['last_page']);

        $this->assertCount(130, $ids);
        $this->assertCount(130, array_unique($ids));
    }
}
