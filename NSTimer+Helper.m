
#import "NSTimer+Helper.h"
#import <objc/runtime.h>

#pragma mark - TargetWrapper

@interface TargetWrapper : NSObject

@property (weak, nonatomic) id target;
@property (weak, nonatomic) NSTimer *timer;

- (instancetype)initWithTarget:(id)target;

@end

@implementation TargetWrapper

- (instancetype)initWithTarget:(id)target {
    if (self = [super init]) {
        self.target = target;
    }
    
    return self;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [TargetWrapper instanceMethodSignatureForSelector:@selector(invalidate)];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    invocation.target = self;
    invocation.selector = @selector(invalidate);
    [invocation invoke];
}

- (void)invalidate {
    if ([_timer isValid]) {
        [_timer invalidate];
    }
}

@end

#pragma mark - NSTimer+Helper

@implementation NSTimer (Helper)

+ (void)load {
    Method originalMethod = class_getClassMethod(self.class, @selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:));
    Method exchangeMethod = class_getClassMethod(self.class, @selector(wb_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:));
    method_exchangeImplementations(originalMethod, exchangeMethod);
}

#pragma mark - Event Response

+ (NSTimer *)wb_scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo {
    TargetWrapper *wrapper = [[TargetWrapper alloc] initWithTarget:aTarget];
    NSTimer *timer = [self wb_scheduledTimerWithTimeInterval:ti target:wrapper selector:aSelector userInfo:userInfo repeats:yesOrNo];
    wrapper.timer = timer;
    return timer;
}

@end
