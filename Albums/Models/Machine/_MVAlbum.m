// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVAlbum.m instead.

#import "_MVAlbum.h"

const struct MVAlbumAttributes MVAlbumAttributes = {
	.artworkUrl = @"artworkUrl",
	.createdAt = @"createdAt",
	.displayedAsReleased = @"displayedAsReleased",
	.hidden = @"hidden",
	.iTunesId = @"iTunesId",
	.iTunesStoreUrl = @"iTunesStoreUrl",
	.name = @"name",
	.releaseDate = @"releaseDate",
	.sectionHeader = @"sectionHeader",
	.shortName = @"shortName",
	.type = @"type",
};

const struct MVAlbumRelationships MVAlbumRelationships = {
	.artist = @"artist",
};

const struct MVAlbumFetchedProperties MVAlbumFetchedProperties = {
};

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

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"displayedAsReleasedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"displayedAsReleased"];
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
	if ([key isEqualToString:@"typeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"type"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic artworkUrl;






@dynamic createdAt;






@dynamic displayedAsReleased;



- (BOOL)displayedAsReleasedValue {
	NSNumber *result = [self displayedAsReleased];
	return [result boolValue];
}

- (void)setDisplayedAsReleasedValue:(BOOL)value_ {
	[self setDisplayedAsReleased:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveDisplayedAsReleasedValue {
	NSNumber *result = [self primitiveDisplayedAsReleased];
	return [result boolValue];
}

- (void)setPrimitiveDisplayedAsReleasedValue:(BOOL)value_ {
	[self setPrimitiveDisplayedAsReleased:[NSNumber numberWithBool:value_]];
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





@dynamic iTunesStoreUrl;






@dynamic name;






@dynamic releaseDate;






@dynamic sectionHeader;






@dynamic shortName;






@dynamic type;



- (int16_t)typeValue {
	NSNumber *result = [self type];
	return [result shortValue];
}

- (void)setTypeValue:(int16_t)value_ {
	[self setType:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveTypeValue {
	NSNumber *result = [self primitiveType];
	return [result shortValue];
}

- (void)setPrimitiveTypeValue:(int16_t)value_ {
	[self setPrimitiveType:[NSNumber numberWithShort:value_]];
}





@dynamic artist;

	






@end
