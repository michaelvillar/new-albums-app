// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVArtist.m instead.

#import "_MVArtist.h"

@implementation MVArtistID
@end

@implementation _MVArtist

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Artist";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Artist" inManagedObjectContext:moc_];
}

- (MVArtistID*)objectID {
	return (MVArtistID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"fetchAlbumsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fetchAlbums"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"iTunesIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"iTunesId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic fetchAlbums;



- (BOOL)fetchAlbumsValue {
	NSNumber *result = [self fetchAlbums];
	return [result boolValue];
}

- (void)setFetchAlbumsValue:(BOOL)value_ {
	[self setFetchAlbums:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveFetchAlbumsValue {
	NSNumber *result = [self primitiveFetchAlbums];
	return [result boolValue];
}

- (void)setPrimitiveFetchAlbumsValue:(BOOL)value_ {
	[self setPrimitiveFetchAlbums:[NSNumber numberWithBool:value_]];
}





@dynamic iTunesId;



- (long long)iTunesIdValue {
	NSNumber *result = [self iTunesId];
	return [result longLongValue];
}

- (void)setITunesIdValue:(long long)value_ {
	[self setITunesId:[NSNumber numberWithLongLong:value_]];
}

- (long long)primitiveITunesIdValue {
	NSNumber *result = [self primitiveITunesId];
	return [result longLongValue];
}

- (void)setPrimitiveITunesIdValue:(long long)value_ {
	[self setPrimitiveITunesId:[NSNumber numberWithLongLong:value_]];
}





@dynamic name;






@dynamic albums;

	
- (NSMutableSet*)albumsSet {
	[self willAccessValueForKey:@"albums"];
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"albums"];
	[self didAccessValueForKey:@"albums"];
	return result;
}
	

@dynamic names;

	
- (NSMutableSet*)namesSet {
	[self willAccessValueForKey:@"names"];
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"names"];
	[self didAccessValueForKey:@"names"];
	return result;
}
	





@end
