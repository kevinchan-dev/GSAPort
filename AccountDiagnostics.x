#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

// Inspect only error domains/codes, never account objects or userInfo values.
static void GSAPortLogAccountSave(BOOL success, NSError *error) {
    NSLog(@"[GSAPort][diagnostic] account save success=%d", success);
    for (NSUInteger depth = 0; error && depth < 5; depth++) {
        NSLog(@"[GSAPort][diagnostic] account save error depth=%lu domain=%@ code=%ld",
              (unsigned long)depth, error.domain, (long)error.code);
        id underlying = error.userInfo[NSUnderlyingErrorKey];
        error = [underlying isKindOfClass:[NSError class]] ? underlying : nil;
    }
}

%hook ACAccountStore

- (void)_saveAccount:(ACAccount *)account verify:(BOOL)verify dataclassActions:(NSDictionary *)actions completion:(void (^)(BOOL, NSError *))completion {
    if (!completion) {
        %orig;
        return;
    }
    NSLog(@"[GSAPort][diagnostic] saving account verify=%d", verify);
    %orig(account, verify, actions, ^(BOOL success, NSError *error) {
        GSAPortLogAccountSave(success, error);
        completion(success, error);
    });
}

%end
