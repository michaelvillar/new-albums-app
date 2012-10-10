// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVArtistName.h instead.

#import <CoreData/CoreData.h>
#import "MVBaseModel.h"

extern const struct MVArtistNameAttributes {
	__unsafe_unretained NSString *name;
} MVArtistNameAttributes;

extern const struct MVArtistNameRelationships {
	__unsafe_unretained NSString *artist;
} MVArtistNameRelationships;

extern const struct MVArtistNameFetchedProperties {
} MVArtistNameFetchedProperties;

@class MVArtist;



@interface MVArtistNameID : NSManagedObjectID {}
@end

@interface _MVArtistName : MVBaseModel {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MVArtistNameID*)objectID;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) MVArtist* artist;

//- (BOOL)validateArtist:(id*)value_ error:(NSError**)error_;





@end

@interface _MVArtistName (CoreDataGeneratedAccessors)

@end

@interface _MVArtistName (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (MVArtist*)primitiveArtist;
- (void)setPrimitiveArtist:(MVArtist*)value;


@end
