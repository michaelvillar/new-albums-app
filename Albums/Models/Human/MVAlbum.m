#import "MVAlbum.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbum ()

@property (readwrite, nonatomic) NSString *albumType;
@property (readonly, strong, nonatomic) NSDateFormatter *monthDayDateFormatter;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbum

@synthesize albumType             = albumType_,
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
  
  if(!self.shortName)
    [self processShortNameAndType];
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
- (NSString*)albumType
{
  if(!self.shortName)
    [self processShortNameAndType];
  if(self.typeValue == kMVAlbumTypeSingle)
    return @"Single";
  else if(self.typeValue == kMVAlbumTypeEP)
    return @"EP";
  else if(self.typeValue == kMVAlbumTypeLive)
    return @"Live";
  else if(self.typeValue == kMVAlbumTypeDeluxe)
    return @"Deluxe";
  return nil;
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
#pragma mark Public Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)processShortNameAndType
{
  NSRegularExpression *regex;
  NSString *pattern;
  NSMutableString *mName = [NSMutableString stringWithString:self.name];
  
  // By default it's an Album
  self.typeValue = kMVAlbumTypeAlbum;
  
  // Single Detection
  if(mName.length > 9 &&
     [[mName substringFromIndex:mName.length - 9] isEqualToString:@" - Single"])
  {
    self.typeValue = kMVAlbumTypeSingle;
    [mName deleteCharactersInRange:NSMakeRange(mName.length - 9, 9)];
  }
  
  // EP Detection
  else if(mName.length > 5 &&
          [[mName substringFromIndex:mName.length - 5] isEqualToString:@" - EP"])
  {
    self.typeValue = kMVAlbumTypeEP;
    [mName deleteCharactersInRange:NSMakeRange(mName.length - 5, 5)];
  }
  
  // Deluxe Detection
  pattern = @"\\([^\\)]*Deluxe[^\\)]*\\)";
  regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:NSRegularExpressionCaseInsensitive
                                                      error:nil];
  if([regex numberOfMatchesInString:mName options:0 range:NSMakeRange(0, mName.length)] > 0)
  {
    self.typeValue = kMVAlbumTypeDeluxe;
    [regex replaceMatchesInString:mName options:0
                            range:NSMakeRange(0, mName.length) withTemplate:@""];
  }
  
  // Live Detection
  pattern = @"\\([^\\)]*Live[^\\)]*\\)";
  regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:NSRegularExpressionCaseInsensitive
                                                      error:nil];
  if([regex numberOfMatchesInString:mName options:0 range:NSMakeRange(0, mName.length)] > 0)
  {
    self.typeValue = kMVAlbumTypeLive;
    [regex replaceMatchesInString:mName options:0
                            range:NSMakeRange(0, mName.length) withTemplate:@""];
  }

  // Feat stuff replacements
  pattern = @"\\[feat\\. .[^\\]]*\\]";
  regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:NSRegularExpressionCaseInsensitive
                                                      error:nil];
  [regex replaceMatchesInString:mName options:0 range:NSMakeRange(0, mName.length) withTemplate:@""];
  
  pattern = @"\\(feat\\. .[^\\)]*\\)";
  regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:NSRegularExpressionCaseInsensitive
                                                      error:nil];
  [regex replaceMatchesInString:mName options:0 range:NSMakeRange(0, mName.length) withTemplate:@""];
  
  self.shortName = mName;
}

@end
