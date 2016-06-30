#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


// enable setting hex colors
@interface UIColor (util)
+ (UIColor *) colorWithHexString:(NSString *)hex;
+ (UIColor *) colorWithHexValue: (NSInteger) hex;
@end

// asynchronous image load with cache
@interface UIImageView(Network)
@property (nonatomic, copy) NSURL *imageURL;
- (void) loadImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder cachingKey:(NSString*)key;
- (void) loadInstantImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder cachingKey:(NSString*)key;
@end

// Utils class
@interface Utils : NSObject
+ (NSInteger)secondsForTimeString:(NSString *)string;
+ (NSString *)timeFormatted:(NSInteger)totalSeconds;
+ (NSInteger)parseISO8601Time:(NSString*)duration;
@end

@interface NSString ( containsCategory )
- (BOOL) hasString: (NSString*) substring;
@end