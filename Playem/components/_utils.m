#import "_utils.h"
#import "FTWCache.h"
#import <objc/runtime.h>

static char URL_KEY;

@implementation UIColor (util)

// Create a color using a string with a webcolor
// ex. [UIColor colorWithHexString:@"#03047F"]
+ (UIColor *) colorWithHexString:(NSString *)hexstr {
    NSScanner *scanner;
    unsigned int rgbval;
    
    scanner = [NSScanner scannerWithString: hexstr];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt: &rgbval];
    
    return [UIColor colorWithHexValue: rgbval];
}

// Create a color using a hex RGB value
// ex. [UIColor colorWithHexValue: 0x03047F]
+ (UIColor *) colorWithHexValue: (NSInteger) rgbValue {
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                           green:((float)((rgbValue & 0xFF00) >> 8))/255.0
                            blue:((float)(rgbValue & 0xFF))/255.0
                           alpha:1.0];
    
}
@end


// asynchronous image load with cache
@implementation UIImageView(Network)

@dynamic imageURL;

- (void) loadImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder cachingKey:(NSString*)key {
	self.imageURL = url;
	self.image = placeholder;
	
	NSData *cachedData = [FTWCache objectForKey:key];
	if (cachedData) {
        //NSLog(@"Image loaded from cache");
        self.imageURL   = nil;
        self.image      = [UIImage imageWithData:cachedData];
        return;
	}
    
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
	dispatch_async(queue, ^{
        //NSLog(@"Image downloaded from url");
		NSData *data = [NSData dataWithContentsOfURL:url];
		
		UIImage *imageFromData = [UIImage imageWithData:data];
		
		[FTWCache setObject:data forKey:key];
        
		if (imageFromData) {
			if ([self.imageURL.absoluteString isEqualToString:url.absoluteString]) {
				dispatch_sync(dispatch_get_main_queue(), ^{
					self.image = imageFromData;
				});
			} else {
                //NSLog(@"urls are not the same, bailing out!");
			}
		}
		self.imageURL = nil;
	});
}

- (void) loadInstantImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder cachingKey:(NSString*)key {
    self.imageURL = url;
    self.image = placeholder;
    
    NSData *cachedData = [FTWCache objectForKey:key];
    if (cachedData) {
        //NSLog(@"Image loaded from cache");
        self.imageURL   = nil;
        self.image      = [UIImage imageWithData:cachedData];
        return;
    }
    
    //NSLog(@"Image downloaded from url");
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *imageFromData = [UIImage imageWithData:data];
    
    [FTWCache setObject:data forKey:key];
    if (imageFromData) {
        if ([self.imageURL.absoluteString isEqualToString:url.absoluteString]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.image = imageFromData;
            });
        } else {
            //NSLog(@"urls are not the same, bailing out!");
        }
    }
    self.imageURL = nil;
    
}

- (void) setImageURL:(NSURL *)newImageURL {
	objc_setAssociatedObject(self, &URL_KEY, newImageURL, OBJC_ASSOCIATION_COPY);
}

- (NSURL*) imageURL {
	return objc_getAssociatedObject(self, &URL_KEY);
}

@end


@implementation Utils

+ (NSInteger)secondsForTimeString:(NSString *)string
{
    
    NSArray *components = [string componentsSeparatedByString:@":"];

    NSInteger minutes = [[components objectAtIndex:0] integerValue];
    NSInteger seconds = [[components objectAtIndex:1] integerValue];
    
    return (minutes * 60) + seconds;
}

+ (NSString *)timeFormatted:(NSInteger)totalSeconds
{
    long hours = totalSeconds / (60 * 60);
    
    int divisor_for_minutes = totalSeconds % (60 * 60);
    int minutes = divisor_for_minutes / 60;
    
    int divisor_for_seconds = divisor_for_minutes % 60;
    int seconds = divisor_for_seconds;
    
    NSString *timeString =@"";
    NSString *formatString=@"";
    if(hours > 0){
        formatString=hours==1?@"%dh":@"%dh";
        timeString = [timeString stringByAppendingString:[NSString stringWithFormat:formatString,hours]];
    }
    if(minutes > 0 || hours > 0 ){
        formatString=minutes==1?@" %dm":@" %dm";
        timeString = [timeString stringByAppendingString:[NSString stringWithFormat:formatString,minutes]];
    }
    if(seconds > 0 || hours > 0 || minutes > 0){
        formatString=seconds==1?@" %ds":@" %ds";
        timeString  = [timeString stringByAppendingString:[NSString stringWithFormat:formatString,seconds]];
    } else {
        timeString = @"0s";
    }
    return timeString;
}

+ (NSInteger)parseISO8601Time:(NSString*)duration
{
    NSInteger hours = 0;
    NSInteger minutes = 0;
    NSInteger seconds = 0;
    
    duration = [duration substringFromIndex:[duration rangeOfString:@"T"].location];
    
    while ([duration length] > 1) {
        duration = [duration substringFromIndex:1];
        
        NSScanner *scanner = [[NSScanner alloc] initWithString:duration];
        
        NSString *durationPart = [[NSString alloc] init];
        [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] intoString:&durationPart];
        
        NSRange rangeOfDurationPart = [duration rangeOfString:durationPart];
        
        duration = [duration substringFromIndex:rangeOfDurationPart.location + rangeOfDurationPart.length];
        
        if ([[duration substringToIndex:1] isEqualToString:@"H"]) {
            hours = [durationPart intValue];
        }
        if ([[duration substringToIndex:1] isEqualToString:@"M"]) {
            minutes = [durationPart intValue];
        }
        if ([[duration substringToIndex:1] isEqualToString:@"S"]) {
            seconds = [durationPart intValue];
        }
    }
    
    return (hours*3600 + minutes*60 + seconds);
}

@end

@implementation NSString ( containsCategory )

- (BOOL) hasString: (NSString*) substring
{
    NSRange range = [self rangeOfString : substring];
    BOOL found = ( range.location != NSNotFound );
    return found;
}

@end