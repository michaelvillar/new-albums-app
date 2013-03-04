//
//  NSString+Levenshtein.h
//  PyHelp
//
//  Modified by Michael Bianco on 12/2/11.
//	<http://mabblog.com>
//
//  Created by Rick Bourner on Sat Aug 09 2003.
//  rick@bourner.com

#import <Foundation/Foundation.h>

@interface NSString (Levenshtein)

// calculate the smallest distance between all words in stringA and stringB
- (CGFloat) compareWithString: (NSString *) stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;

// calculate the distance between two string treating them each as a single word
- (NSInteger) compareWithWord:(NSString *) stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;
@end
