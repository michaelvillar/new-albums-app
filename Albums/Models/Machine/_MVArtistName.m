// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVArtistName.m instead.

#import "_MVArtistName.h"

const struct MVArtistNameAttributes MVArtistNameAttributes = {
	.name = @"name",
};

const struct MVArtistNameRelationships MVArtistNameRelationships = {
	.artist = @"artist",
};

const struct MVArtistNameFetchedProperties MVArtistNameFetchedProperties = {
};

@implementation MVArtistNameID
@end

@implementation _MVArtistName

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ArtistName" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ArtistName";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ArtistName" inManagedObjectContext:moc_];
}

- (MVArtistNameID*)objectID {
	return (MVArtistNameID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic artist;

	






@end
