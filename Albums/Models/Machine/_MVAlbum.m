// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVAlbum.m instead.

#import "_MVAlbum.h"

@implementation MVAlbumID
@end

@implementation _MVAlbum

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Album";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Album" inManagedObjectContext:moc_];
}

- (MVAlbumID*)objectID {
	return (MVAlbumID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"iTunesIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"iTunesId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic artworkUrl;






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





@dynamic iTunesStoreUrl;






@dynamic name;






@dynamic releaseDate;






@dynamic artist;

	





@end
