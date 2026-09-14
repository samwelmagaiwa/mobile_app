<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\Block;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class BlockController extends Controller
{
    #[OA\Get(
        path: '/rental/blocks/{propertyId}',
        summary: 'List resources',
        security: [['bearerAuth' => []]],
        tags: ['Rental / Block'],
        parameters: [
            new OA\Parameter(name: 'propertyId', in: 'path', required: true, schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'Success')],
    )]
    public function index(Request $request, $propertyId)
    {
        $blocks = Block::where('property_id', $propertyId)
            ->with('houses')
            ->get();
        return ResponseHelper::success($blocks);
    }

    #[OA\Post(

        path: '/rental/blocks/{propertyId}',

        summary: 'Create a resource',

        security: [['bearerAuth' => []]],

        tags: ['Rental / Block'],

        parameters: [

            new OA\Parameter(name: 'propertyId', in: 'path', required: true, schema: new OA\Schema(type: 'string')),

        ],

                requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
            required: ['name'],
                properties: [
                new OA\Property(property: 'name', type: 'string'),
                new OA\Property(property: 'description', type: 'string', nullable: true),
                ],
            ),
        ),
responses: [new OA\Response(response: 200, description: 'Success')],

    )]

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

    #[OA\Get(

        path: '/rental/blocks/block/{id}',

        summary: 'Get a single resource',

        security: [['bearerAuth' => []]],

        tags: ['Rental / Block'],

        parameters: [

            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'string')),

        ],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function show($id)
    {
        $block = Block::with(['property', 'houses'])->findOrFail($id);
        return ResponseHelper::success($block);
    }

    #[OA\Put(

        path: '/rental/blocks/block/{id}',

        summary: 'Update a resource',

        security: [['bearerAuth' => []]],

        tags: ['Rental / Block'],

        parameters: [

            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'string')),

        ],

                requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                properties: [
                new OA\Property(property: 'name', type: 'string', nullable: true),
                new OA\Property(property: 'description', type: 'string', nullable: true),
                ],
            ),
        ),
responses: [new OA\Response(response: 200, description: 'Success')],

    )]

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

    #[OA\Delete(

        path: '/rental/blocks/block/{id}',

        summary: 'Delete a resource',

        security: [['bearerAuth' => []]],

        tags: ['Rental / Block'],

        parameters: [

            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'string')),

        ],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

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