<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\Block;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class BlockController extends Controller
{
    public function index(Request $request, $propertyId)
    {
        $blocks = Block::where('property_id', $propertyId)
            ->with('houses')
            ->get();
        return ResponseHelper::success($blocks);
    }

    public function store(Request $request, $propertyId)
    {
        $request->validate([
            'name' => 'required|string',
            'description' => 'nullable|string',
        ]);

        $block = Block::create([
            'property_id' => $propertyId,
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return ResponseHelper::success($block, 'Block created successfully', 201);
    }

    public function show($id)
    {
        $block = Block::with(['property', 'houses'])->findOrFail($id);
        return ResponseHelper::success($block);
    }

    public function update(Request $request, $id)
    {
        $block = Block::findOrFail($id);
        
        $request->validate([
            'name' => 'sometimes|string',
            'description' => 'nullable|string',
        ]);

        $block->update($request->only(['name', 'description']));
        
        return ResponseHelper::success($block, 'Block updated successfully');
    }

    public function destroy($id)
    {
        $block = Block::findOrFail($id);
        
        if ($block->houses()->count() > 0) {
            return ResponseHelper::error('Cannot delete block with houses. Remove houses first.', 400);
        }
        
        $block->delete();
        
        return ResponseHelper::success(null, 'Block deleted successfully');
    }
}