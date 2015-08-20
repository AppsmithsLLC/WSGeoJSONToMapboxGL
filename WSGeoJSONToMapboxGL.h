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

#import <Foundation/Foundation.h>

@interface WSGeoJSONToMapboxGL : NSObject

typedef void(^CreateGeometriesCompletionBlock)(NSArray* shapes, NSError* error);

/*!
 @brief             Deserializes a geoJSON string for use with MapboxGL using a completion block.
 
 @discussion        This method accepts an NSString representing a geoJSON object then deserializes it, generating
                    the MapboxGL components defined by the object.
 
 @param  geoJSON    Must be a properly formatted geoJSON string.
                    All quotes (") must be escaped (\).
 
 @param completion  CreateGeometriesCompletionBlock wraps the method and returns an NSArray of MGLShape objects (shapes).
                    If there is an error, shapes will be nil and error will be populated, so check the error object before
                    acting on shapes.
 
 @return void
 */
+ (void)getGeometriesFromGeoJSON:(NSString*)geoJSON withCompletion:(CreateGeometriesCompletionBlock)completion;

@end
