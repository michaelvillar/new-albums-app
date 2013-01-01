// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVArtist.m instead.

#import "_MVArtist.h"

const struct MVArtistAttributes MVArtistAttributes = {
	.fetchAlbums = @"fetchAlbums",
	.hidden = @"hidden",
	.iTunesId = @"iTunesId",
	.name = @"name",
};

const struct MVArtistRelationships MVArtistRelationships = {
	.albums = @"albums",
	.names = @"names",
};

const struct MVArtistFetchedProperties MVArtistFetchedProperties = {
};

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

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"fetchAlbumsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fetchAlbums"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"hiddenValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"hidden"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"iTunesIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"iTunesId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
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





@dynamic hidden;



- (BOOL)hiddenValue {
	NSNumber *result = [self hidden];
	return [result boolValue];
}

- (void)setHiddenValue:(BOOL)value_ {
	[self setHidden:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveHiddenValue {
	NSNumber *result = [self primitiveHidden];
	return [result boolValue];
}

- (void)setPrimitiveHiddenValue:(BOOL)value_ {
	[self setPrimitiveHidden:[NSNumber numberWithBool:value_]];
}





@dynamic iTunesId;



- (int64_t)iTunesIdValue {
	NSNumber *result = [self iTunesId];
	return [result longLongValue];
}

- (void)setITunesIdValue:(int64_t)value_ {
	[self setITunesId:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveITunesIdValue {
	NSNumber *result = [self primitiveITunesId];
	return [result longLongValue];
}

- (void)setPrimitiveITunesIdValue:(int64_t)value_ {
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
