//
//  Fingerprint.h
//  Redpin
/**  This file is part of the Redpin project.
 * 
 *  Redpin is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  Redpin is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with Redpin. If not, see <http://www.gnu.org/licenses/>.
 *
 * © Copyright ETH Zurich, Pascal Brogle, Philipp Bolliger, 2010, ALL RIGHTS RESERVED.
 * 
 *  www.redpin.org
 */


#import <CoreData/CoreData.h>
#import "DBEntity.h"

@class Measurement;
@class Location;

@interface Fingerprint :  DBEntity  
{
}

@property (nonatomic, retain) Measurement * measurement;
@property (nonatomic, retain) Location * location;

- (id) proxyForJson;
+ (Fingerprint *) fromJSON:(NSDictionary *) dict;

@end



