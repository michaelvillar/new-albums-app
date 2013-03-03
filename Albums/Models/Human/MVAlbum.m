#import "MVAlbum.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbum ()

@property (readwrite, nonatomic) NSString *albumType;
@property (readonly, strong, nonatomic) NSDateFormatter *monthDayDateFormatter;

- (void)processShortName;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbum

@synthesize shortName             = shortName_,
            albumType             = albumType_,
            monthDayDateFormatter = monthDayDateFormatter_,
            monthDayReleaseDate   = monthDayReleaseDate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Override Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willSave
{
  [super willSave];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)sectionHeader
{
  if([self.releaseDate compare:[NSDate date]] == NSOrderedDescending)
    return @"Upcoming";
  return self.releaseDate.description;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)shortName
{
  if(!shortName_)
  {
    [self processShortName];
  }
  return shortName_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)albumType
{
  if(!shortName_)
    [self processShortName];
  return albumType_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)monthDayReleaseDate
{
  if(!monthDayReleaseDate_ && self.releaseDate)
  {
    monthDayReleaseDate_ = [self.monthDayDateFormatter stringFromDate:self.releaseDate];
  }
  return monthDayReleaseDate_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDateFormatter*)monthDayDateFormatter
{
  if(!monthDayDateFormatter_)
  {
    NSString *template = @"ddMM";
    NSLocale *locale = [NSLocale currentLocale];
    monthDayDateFormatter_ = [[NSDateFormatter alloc] init];
    monthDayDateFormatter_.dateFormat = [NSDateFormatter dateFormatFromTemplate:template
                                                                        options:0
                                                                         locale:locale];
  }
  return monthDayDateFormatter_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)processShortName
{
  NSMutableString *mName = [NSMutableString stringWithString:self.name];
  if(mName.length > 9 &&
     [[mName substringFromIndex:mName.length - 9] isEqualToString:@" - Single"])
  {
    self.albumType = @"Single";
    [mName deleteCharactersInRange:NSMakeRange(mName.length - 9, 9)];
  }
  if(mName.length > 5 &&
     [[mName substringFromIndex:mName.length - 5] isEqualToString:@" - EP"])
  {
    self.albumType = @"EP";
    [mName deleteCharactersInRange:NSMakeRange(mName.length - 5, 5)];
  }
  
  NSString *pattern = @"\\[feat\\. .[^\\]]*\\]";
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:pattern
                                options:NSRegularExpressionCaseInsensitive
                                error:nil];
  [regex replaceMatchesInString:mName options:0 range:NSMakeRange(0, mName.length) withTemplate:@""];
  
  pattern = @"\\(feat\\. .[^\\)]*\\)";
  regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:NSRegularExpressionCaseInsensitive
                                                      error:nil];
  [regex replaceMatchesInString:mName options:0 range:NSMakeRange(0, mName.length) withTemplate:@""];
  
  shortName_ = mName;
}

@end
