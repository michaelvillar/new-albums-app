// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVAlbum.h instead.

#import <CoreData/CoreData.h>
#import "MVBaseModel.h"

@class MVArtist;







@interface MVAlbumID : NSManagedObjectID {}
@end

@interface _MVAlbum : MVBaseModel {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MVAlbumID*)objectID;




@property (nonatomic, strong) NSString *artworkUrl;


//- (BOOL)validateArtworkUrl:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *iTunesId;


@property long long iTunesIdValue;
- (long long)iTunesIdValue;
- (void)setITunesIdValue:(long long)value_;

//- (BOOL)validateITunesId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *iTunesStoreUrl;


//- (BOOL)validateITunesStoreUrl:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *releaseDate;


//- (BOOL)validateReleaseDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) MVArtist* artist;

//- (BOOL)validateArtist:(id*)value_ error:(NSError**)error_;




@end

@interface _MVAlbum (CoreDataGeneratedAccessors)

@end

@interface _MVAlbum (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveArtworkUrl;
- (void)setPrimitiveArtworkUrl:(NSString*)value;




- (NSNumber*)primitiveITunesId;
- (void)setPrimitiveITunesId:(NSNumber*)value;

- (long long)primitiveITunesIdValue;
- (void)setPrimitiveITunesIdValue:(long long)value_;




- (NSString*)primitiveITunesStoreUrl;
- (void)setPrimitiveITunesStoreUrl:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSDate*)primitiveReleaseDate;
- (void)setPrimitiveReleaseDate:(NSDate*)value;





- (MVArtist*)primitiveArtist;
- (void)setPrimitiveArtist:(MVArtist*)value;


@end
