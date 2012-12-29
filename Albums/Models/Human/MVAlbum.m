#import "MVAlbum.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbum

@synthesize shortName       = shortName_;

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
    NSMutableString *mName = [NSMutableString stringWithString:self.name];
    if(mName.length > 9 &&
       [[mName substringFromIndex:mName.length - 9] isEqualToString:@" - Single"])
      [mName deleteCharactersInRange:NSMakeRange(mName.length - 9, 9)];
    if(mName.length > 5 &&
       [[mName substringFromIndex:mName.length - 5] isEqualToString:@" - EP"])
      [mName deleteCharactersInRange:NSMakeRange(mName.length - 5, 5)];
    
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
  return shortName_;
}

@end
