// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MVArtist.h instead.

#import <CoreData/CoreData.h>
#import "MVBaseModel.h"

@class MVAlbum;
@class MVArtistName;





@interface MVArtistID : NSManagedObjectID {}
@end

@interface _MVArtist : MVBaseModel {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MVArtistID*)objectID;




@property (nonatomic, strong) NSNumber *fetchAlbums;


@property BOOL fetchAlbumsValue;
- (BOOL)fetchAlbumsValue;
- (void)setFetchAlbumsValue:(BOOL)value_;

//- (BOOL)validateFetchAlbums:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *iTunesId;


@property long long iTunesIdValue;
- (long long)iTunesIdValue;
- (void)setITunesIdValue:(long long)value_;

//- (BOOL)validateITunesId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* albums;

- (NSMutableSet*)albumsSet;




@property (nonatomic, strong) NSSet* names;

- (NSMutableSet*)namesSet;




@end

@interface _MVArtist (CoreDataGeneratedAccessors)

- (void)addAlbums:(NSSet*)value_;
- (void)removeAlbums:(NSSet*)value_;
- (void)addAlbumsObject:(MVAlbum*)value_;
- (void)removeAlbumsObject:(MVAlbum*)value_;

- (void)addNames:(NSSet*)value_;
- (void)removeNames:(NSSet*)value_;
- (void)addNamesObject:(MVArtistName*)value_;
- (void)removeNamesObject:(MVArtistName*)value_;

@end

@interface _MVArtist (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveFetchAlbums;
- (void)setPrimitiveFetchAlbums:(NSNumber*)value;

- (BOOL)primitiveFetchAlbumsValue;
- (void)setPrimitiveFetchAlbumsValue:(BOOL)value_;




- (NSNumber*)primitiveITunesId;
- (void)setPrimitiveITunesId:(NSNumber*)value;

- (long long)primitiveITunesIdValue;
- (void)setPrimitiveITunesIdValue:(long long)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableSet*)primitiveAlbums;
- (void)setPrimitiveAlbums:(NSMutableSet*)value;



- (NSMutableSet*)primitiveNames;
- (void)setPrimitiveNames:(NSMutableSet*)value;


@end
