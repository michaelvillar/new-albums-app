// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVOption.h instead.

#import <CoreData/CoreData.h>
#import "MVBaseModel.h"

extern const struct MVOptionAttributes {
	__unsafe_unretained NSString *key;
	__unsafe_unretained NSString *value;
} MVOptionAttributes;

extern const struct MVOptionRelationships {
} MVOptionRelationships;

extern const struct MVOptionFetchedProperties {
} MVOptionFetchedProperties;





@interface MVOptionID : NSManagedObjectID {}
@end

@interface _MVOption : MVBaseModel {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MVOptionID*)objectID;





@property (nonatomic, strong) NSString* key;



//- (BOOL)validateKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* value;



//- (BOOL)validateValue:(id*)value_ error:(NSError**)error_;






@end

@interface _MVOption (CoreDataGeneratedAccessors)

@end

@interface _MVOption (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveKey;
- (void)setPrimitiveKey:(NSString*)value;




- (NSString*)primitiveValue;
- (void)setPrimitiveValue:(NSString*)value;




@end
