<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\State;
use App\Models\Lga;
use App\Models\Ward;
use App\Models\Village;
use App\Models\Place;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function getRegions()
    {
        return response()->json(['success' => true, 'data' => State::orderBy('name')->get()]);
    }

    public function getDistricts(Request $request)
    {
        $request->validate(['region_id' => 'required|integer']);
        $lgas = Lga::where('state_id', $request->region_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $lgas]);
    }

    public function getWards(Request $request)
    {
        $request->request->add(['district_id' => $request->query('district_id')]);
        if (!$request->has('district_id')) {
            return response()->json(['success' => true, 'data' => []]);
        }
        $wards = Ward::where('lga_id', $request->district_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $wards]);
    }

    public function getStreets(Request $request)
    {
        if (!$request->has('ward_id')) {
            return response()->json(['success' => true, 'data' => []]);
        }
        $villages = Village::where('ward_id', $request->ward_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $villages]);
    }

    public function getPlaces(Request $request)
    {
        if (!$request->has('village_id')) {
            return response()->json(['success' => true, 'data' => []]);
        }
        $places = Place::where('village_id', $request->village_id)->orderBy('name')->get();
        return response()->json(['success' => true, 'data' => $places]);
    }
}
