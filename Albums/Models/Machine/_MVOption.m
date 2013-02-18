// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVOption.m instead.

#import "_MVOption.h"

const struct MVOptionAttributes MVOptionAttributes = {
	.key = @"key",
	.value = @"value",
};

const struct MVOptionRelationships MVOptionRelationships = {
};

const struct MVOptionFetchedProperties MVOptionFetchedProperties = {
};

@implementation MVOptionID
@end

@implementation _MVOption

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Option" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Option";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Option" inManagedObjectContext:moc_];
}

- (MVOptionID*)objectID {
	return (MVOptionID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic key;






@dynamic value;











@end
