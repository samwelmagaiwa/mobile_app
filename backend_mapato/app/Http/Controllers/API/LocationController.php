<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\State;
use App\Models\Lga;
use App\Models\Ward;
use App\Models\Village;
use App\Models\Place;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

#[OA\Tag(name: 'Locations', description: 'Shared geography lookup (region -> district -> ward -> village -> place), public and used across every service.')]
class LocationController extends Controller
{
    #[OA\Get(
        path: '/locations/regions',
        summary: 'List all regions',
        tags: ['Locations'],
        responses: [new OA\Response(response: 200, description: 'Region list')],
    )]
    public function getRegions()
    {
        return response()->json(['success' => true, 'data' => State::orderBy('name')->get()]);
    }

    #[OA\Get(
        path: '/locations/districts',
        summary: 'List districts in a region',
        tags: ['Locations'],
        parameters: [
            new OA\Parameter(name: 'region_id', in: 'query', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'District list')],
    )]
    public function getDistricts(Request $request)
    {
        $request->validate(['region_id' => 'required|integer']);
        $lgas = Lga::where('state_id', $request->region_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $lgas]);
    }

    #[OA\Get(

        path: '/locations/wards',

        summary: 'Get wards',

        tags: ['Locations'],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function getWards(Request $request)
    {
        $request->request->add(['district_id' => $request->query('district_id')]);
        if (!$request->has('district_id')) {
            return response()->json(['success' => true, 'data' => []]);
        }
        $wards = Ward::where('lga_id', $request->district_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $wards]);
    }

    #[OA\Get(

        path: '/locations/streets',

        summary: 'Get streets',

        tags: ['Locations'],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function getStreets(Request $request)
    {
        if (!$request->has('ward_id')) {
            return response()->json(['success' => true, 'data' => []]);
        }
        $villages = Village::where('ward_id', $request->ward_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $villages]);
    }

    #[OA\Get(

        path: '/locations/places',

        summary: 'Get places',

        tags: ['Locations'],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function getPlaces(Request $request)
    {
        if (!$request->has('village_id')) {
            return response()->json(['success' => true, 'data' => []]);
        }
        $places = Place::where('village_id', $request->village_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $places]);
    }
}
