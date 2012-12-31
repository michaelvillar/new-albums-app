// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVAlbum.h instead.

#import <CoreData/CoreData.h>
#import "MVBaseModel.h"

extern const struct MVAlbumAttributes {
	__unsafe_unretained NSString *artworkUrl;
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *iTunesId;
	__unsafe_unretained NSString *iTunesStoreUrl;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *releaseDate;
	__unsafe_unretained NSString *sectionHeader;
} MVAlbumAttributes;

extern const struct MVAlbumRelationships {
	__unsafe_unretained NSString *artist;
} MVAlbumRelationships;

extern const struct MVAlbumFetchedProperties {
} MVAlbumFetchedProperties;

@class MVArtist;









@interface MVAlbumID : NSManagedObjectID {}
@end

@interface _MVAlbum : MVBaseModel {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MVAlbumID*)objectID;





@property (nonatomic, strong) NSString* artworkUrl;



//- (BOOL)validateArtworkUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* iTunesId;



@property int64_t iTunesIdValue;
- (int64_t)iTunesIdValue;
- (void)setITunesIdValue:(int64_t)value_;

//- (BOOL)validateITunesId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* iTunesStoreUrl;



//- (BOOL)validateITunesStoreUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* releaseDate;



//- (BOOL)validateReleaseDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* sectionHeader;



//- (BOOL)validateSectionHeader:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) MVArtist *artist;

//- (BOOL)validateArtist:(id*)value_ error:(NSError**)error_;





@end

@interface _MVAlbum (CoreDataGeneratedAccessors)

@end

@interface _MVAlbum (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveArtworkUrl;
- (void)setPrimitiveArtworkUrl:(NSString*)value;




- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSNumber*)primitiveITunesId;
- (void)setPrimitiveITunesId:(NSNumber*)value;

- (int64_t)primitiveITunesIdValue;
- (void)setPrimitiveITunesIdValue:(int64_t)value_;




- (NSString*)primitiveITunesStoreUrl;
- (void)setPrimitiveITunesStoreUrl:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSDate*)primitiveReleaseDate;
- (void)setPrimitiveReleaseDate:(NSDate*)value;




- (NSString*)primitiveSectionHeader;
- (void)setPrimitiveSectionHeader:(NSString*)value;





- (MVArtist*)primitiveArtist;
- (void)setPrimitiveArtist:(MVArtist*)value;


@end
