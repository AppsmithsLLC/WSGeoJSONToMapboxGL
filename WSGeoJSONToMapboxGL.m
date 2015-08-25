//
//  WSGeoJSONToMapboxGL.m
//
//  Created by William Smith on 8/19/15.
//The MIT License (MIT)
//
//Copyright (c) 2015 Websmiths
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  geoJSON object comments from
//  http://geojson.org/geojson-spec.html
//

#import "WSGeoJSONToMapboxGL.h"
#import <MapboxGL/MapboxGL.h>

@implementation WSGeoJSONToMapboxGL

+ (void)getGeometriesFromGeoJSON:(NSString*)geoJSON withCompletion:(CreateGeometriesCompletionBlock)completion
{
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[geoJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSMutableArray *shapes = [NSMutableArray array];
   
    // Load the `features` dictionary for iteration
    //
    for (NSDictionary *feature in jsonDict[@"features"])
    {
        if ([feature[@"geometry"][@"type"] isEqualToString:@"Point"])
        {
            [shapes addObjectsFromArray:[self getPointFromGeoJSONFeature:feature]];
        }
        else if ([feature[@"geometry"][@"type"] isEqualToString:@"MultiPoint"])
        {
            [shapes addObjectsFromArray:[self getPointsFromGeoJSONFeature:feature]];
        }
        else if ([feature[@"geometry"][@"type"] isEqualToString:@"LineString"])
        {
            [shapes addObjectsFromArray:[self getPolylineFromGeoJSONFeature:feature]];
        }
        else if ([feature[@"geometry"][@"type"] isEqualToString:@"MultiLineString"])
        {
            [shapes addObjectsFromArray:[self getPolylinesFromGeoJSONFeature:feature]];
        }
        else if ([feature[@"geometry"][@"type"] isEqualToString:@"Polygon"])
        {
            [shapes addObjectsFromArray:[self getPolygonFromGeoJSONFeature:feature]];
        }
        else if ([feature[@"geometry"][@"type"] isEqualToString:@"MultiPolygon"])
        {
            [shapes addObjectsFromArray:[self getPolygonsFromGeoJSONFeature:feature]];
        }
        else if ([feature[@"geometry"][@"type"] isEqualToString:@"GeometryCollection"])
        {
            //TODO Recursively call this method?
            completion(nil, [NSError errorWithDomain:@"HAAS" code:1 userInfo:[NSDictionary dictionaryWithObject:@"GeometryCollection not yet implemented." forKey:@"message"]]);
        }
    }

    completion(shapes, nil);
}

#pragma mark -
#pragma mark - Shape Renderers

#pragma mark -
#pragma mark - Points

//2.1.2. Point
//For type "Point", the "coordinates" member must be a single position.
//
+(NSArray*)getPointFromGeoJSONFeature:(NSDictionary*)feature
{
    // Get the data for our point
    //
    NSArray *rawCoordinates = feature[@"geometry"][@"coordinates"];
    
    MGLPointAnnotation *point = [self getPointFromPointArray:rawCoordinates];
    point.title = feature[@"properties"][@"name"];
    
    return [NSArray arrayWithObject:point];
}

//2.1.3. MultiPoint
//For type "MultiPoint", the "coordinates" member must be an array of positions.
//
+(NSArray*)getPointsFromGeoJSONFeature:(NSDictionary*)feature
{
    // Get the raw array of data for our points
    //
    NSArray *rawCoordinateArray = feature[@"geometry"][@"coordinates"];
    NSMutableArray *points = [NSMutableArray array];
    
    for (NSUInteger index = 0; index < [rawCoordinateArray count]; index++)
    {
        NSArray *rawPoint = [rawCoordinateArray objectAtIndex:index];
        
        MGLPointAnnotation *point = [self getPointFromPointArray:rawPoint];
        point.title = feature[@"properties"][@"name"];
        
        [points addObject:point];
    }
    
    return points;
}

+(MGLPointAnnotation*)getPointFromPointArray:(NSArray*)rawPoint
{
    // GeoJSON is "longitude, latitude" order, but we need the opposite
    CLLocationDegrees lat = [[rawPoint objectAtIndex:1] doubleValue];
    CLLocationDegrees lng = [[rawPoint objectAtIndex:0] doubleValue];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
    
    // Create our polyline with the formatted coordinates array
    MGLPointAnnotation *point = [[MGLPointAnnotation alloc] init];
    point.coordinate = coordinate;
    
    return point;
}


#pragma mark -
#pragma mark - LineStrings

//2.1.4. LineString
//For type "LineString", the "coordinates" member must be an array of two or more positions.
//
//A LinearRing is closed LineString with 4 or more positions.
//The first and last positions are equivalent (they represent equivalent points).
//Though a LinearRing is not explicitly represented as a GeoJSON geometry type, it is referred to in the Polygon geometry type definition.
//
+(NSArray*)getPolylineFromGeoJSONFeature:(NSDictionary*)feature
{
    NSMutableArray *polylines = [NSMutableArray array];
    
    // Get the raw array of coordinates for our line
    //
    NSArray *rawCoordinates = feature[@"geometry"][@"coordinates"];
    
    // Create our polyline with the formatted coordinates array
    //
    MGLPolyline *polyline = [self getPolylineFromCoordinateArray:rawCoordinates];
    polyline.title = feature[@"properties"][@"name"];
    
    [polylines addObject:polyline];
    
    return polylines;
}


//2.1.5. MultiLineString
//For type "MultiLineString", the "coordinates" member must be an array of LineString coordinate arrays.
//
+(NSArray*)getPolylinesFromGeoJSONFeature:(NSDictionary*)feature
{
    NSMutableArray *polylines = [NSMutableArray array];
    
    // Get the raw array of arrays of coordinates
    //
    NSArray *rawCoordinateArrays = feature[@"geometry"][@"coordinates"];
    
    for (NSUInteger index = 0; index < [rawCoordinateArrays count]; index++)
    {
        // Create our polyline with the formatted coordinates array
        //
        NSArray* rawCoordinates = [rawCoordinateArrays objectAtIndex:index];
        MGLPolyline *polyline = [self getPolylineFromCoordinateArray:rawCoordinates];
        polyline.title = feature[@"properties"][@"name"];
        
        [polylines addObject:polyline];
    }
    
    return polylines;
}

+(MGLPolyline*)getPolylineFromCoordinateArray:(NSArray*)rawCoordinates
{
    NSUInteger coordinatesCount = [rawCoordinates count];
    
    // Create a coordinates array, sized to fit all of the coordinates in the line.
    // This array will hold the properly formatted coordinates for our MGLPolyline.
    //
    CLLocationCoordinate2D coordinates[coordinatesCount];
    
    // Iterate over `rawCoordinates` once for each coordinate on the line
    //
    for (NSUInteger index = 0; index < coordinatesCount; index++)
    {
        // Get the individual coordinate for this index
        //
        NSArray *point = [rawCoordinates objectAtIndex:index];
        
        // GeoJSON is "longitude, latitude" order, but we need the opposite
        CLLocationDegrees lat = [[point objectAtIndex:1] doubleValue];
        CLLocationDegrees lng = [[point objectAtIndex:0] doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
        
        // Add this formatted coordinate to the final coordinates array at the same index
        coordinates[index] = coordinate;
    }
    
    // Create our polyline with the formatted coordinates array
    MGLPolyline *polyline = [MGLPolyline polylineWithCoordinates:coordinates count:coordinatesCount];
    
    return polyline;
}


#pragma mark - Polygons
//2.1.6. Polygon
//For type "Polygon", the "coordinates" member must be an array of LinearRing coordinate arrays.
//For Polygons with multiple rings, the first must be the exterior ring and any others must be interior rings or holes.
//
+(NSArray*)getPolygonFromGeoJSONFeature:(NSDictionary*)feature
{
    NSMutableArray *polygons = [NSMutableArray array];
    
    // Get the raw array of arrays of coordinates
    //
    NSArray *rawCoordinateArrays = feature[@"geometry"][@"coordinates"];
    
    if ([[rawCoordinateArrays firstObject] count] == 2)
    {
        //Array has points, so this is a simple polygon
        //
        MGLPolygon *polygon = [self getPolygonFromCoordinateArray:rawCoordinateArrays];
        polygon.title = feature[@"properties"][@"name"];
        
        [polygons addObject:polygon];
    }
    else
    {
        //Array has a polygon definition, so this is a complex polygon containing holes.
        //
        for (NSUInteger index = 0; index < [rawCoordinateArrays count]; index++)
        {
            // Create our polygon with the formatted coordinates array
            //
            NSArray* rawCoordinates = [rawCoordinateArrays objectAtIndex:index];
            MGLPolygon *polygon = [self getPolygonFromCoordinateArray:rawCoordinates];
            polygon.title = feature[@"properties"][@"name"];
            
            [polygons addObject:polygon];
        }
    }
    
    
    return polygons;
}


//2.1.7. MultiPolygon
//For type "MultiPolygon", the "coordinates" member must be an array of Polygon coordinate arrays.
//
+(NSArray*)getPolygonsFromGeoJSONFeature:(NSDictionary*)feature
{
    NSMutableArray *polygons = [NSMutableArray array];
    
    // Get the raw array of arrays of coordinates
    //
    NSArray *rawCoordinateArrays = feature[@"geometry"][@"coordinates"];
    
    for (NSUInteger index = 0; index < [rawCoordinateArrays count]; index++)
    {
        NSArray *rawPolygonCoordinates = [rawCoordinateArrays objectAtIndex:index];
        
        // Create our polygon with the formatted coordinates array
        //
        MGLPolygon *polygon = [self getPolygonFromCoordinateArray:rawPolygonCoordinates];
        polygon.title = feature[@"properties"][@"name"];

        [polygons addObject:polygon];
    }
    
    return polygons;
}

+(MGLPolygon*)getPolygonFromCoordinateArray:(NSArray*)rawCoordinates
{
    NSUInteger coordinatesCount = [rawCoordinates count];
    
    // Create a coordinates array, sized to fit all of the coordinates in the polygon.
    // This array will hold the properly formatted coordinates for our MGLPolygon.
    //
    CLLocationCoordinate2D coordinates[coordinatesCount];
    
    for (NSUInteger index = 0; index < coordinatesCount; index++)
    {
        NSArray *point = [rawCoordinates objectAtIndex:index];
        
        // GeoJSON is "longitude, latitude" order, but we need the opposite
        //
        CLLocationDegrees lat = [[point objectAtIndex:1] doubleValue];
        CLLocationDegrees lng = [[point objectAtIndex:0] doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
        
        coordinates[index] = coordinate;
    }
    
    // Create our polyline with the formatted coordinates array
    MGLPolygon *polygon = [MGLPolygon polygonWithCoordinates:coordinates count:coordinatesCount];
    
    return polygon;
}

//TODO for future release
//2.1.8 Geometry Collection
//A GeoJSON object with type "GeometryCollection" is a geometry object which represents a collection of geometry objects.
//A geometry collection must have a member with the name "geometries". The value corresponding to "geometries" is an array. Each element in this array is a GeoJSON geometry object.
//
@end
