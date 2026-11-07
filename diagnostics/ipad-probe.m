#import <Foundation/Foundation.h>
#import <asl.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#include <time.h>

static void accountErrors(void) {
    for (NSString *sender in @[@"Preferences", @"accountsd"]) {
        aslmsg query=asl_new(ASL_TYPE_QUERY);
        char since[32]; snprintf(since,sizeof(since),"%ld",(long)time(NULL)-600);
        asl_set_query(query,ASL_KEY_TIME,since,ASL_QUERY_OP_GREATER_EQUAL|ASL_QUERY_OP_NUMERIC);
        asl_set_query(query,ASL_KEY_SENDER,sender.UTF8String,ASL_QUERY_OP_EQUAL);
        aslresponse results=asl_search(NULL,query); aslmsg message; unsigned count=0;
        NSRegularExpression *errors=[NSRegularExpression regularExpressionWithPattern:@"(?:Error Domain=|error domain: ?)([A-Za-z0-9_.-]+)(?: Code=| code: ?)(-?[0-9]+)" options:NSRegularExpressionCaseInsensitive error:NULL];
        while (results && (message=asl_next(results))) {
            const char *raw=asl_get(message,ASL_KEY_MSG); if (!raw) continue;
            NSString *text=[NSString stringWithUTF8String:raw];
            for (NSTextCheckingResult *match in [errors matchesInString:text options:0 range:NSMakeRange(0,text.length)]) {
                printf("ACCOUNT ERROR time=%s sender=%s domain=%s code=%s\n",asl_get(message,ASL_KEY_TIME) ?: "?",sender.UTF8String,[text substringWithRange:[match rangeAtIndex:1]].UTF8String,[text substringWithRange:[match rangeAtIndex:2]].UTF8String); count++;
            }
            for (NSString *marker in @[@"unsupported os", @"terms and conditions", @"unsupported operating system", @"unable to parse", @"invalid response", @"NSURLError", @"SSL", @"certificate"]) {
                if ([text rangeOfString:marker options:NSCaseInsensitiveSearch].location != NSNotFound) printf("ACCOUNT MARKER time=%s sender=%s marker=%s\n",asl_get(message,ASL_KEY_TIME) ?: "?",sender.UTF8String,marker.UTF8String);
            }
        }
        printf("Structured errors for %s: %u\n",sender.UTF8String,count);
        if (results) asl_release(results); asl_free(query);
    }
}

static void recentLogs(void) {
    aslmsg query = asl_new(ASL_TYPE_QUERY);
    char since[32]; snprintf(since, sizeof(since), "%ld", (long)time(NULL)-3600);
    asl_set_query(query, ASL_KEY_TIME, since, ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
    asl_set_query(query, ASL_KEY_MSG, "GSAPort", ASL_QUERY_OP_SUBSTRING);
    aslresponse results = asl_search(NULL, query);
    aslmsg message; unsigned count=0;
    while (results && (message=asl_next(results)) && count++ < 500) {
        const char *raw=asl_get(message, ASL_KEY_MSG);
        NSString *text=raw ? [NSString stringWithUTF8String:raw] : @"";
        if ([text rangeOfString:@"uuid" options:NSCaseInsensitiveSearch].location != NSNotFound) text=@"[GSAPort] requesting anisette (device identifier omitted)";
        if ([text hasPrefix:@"[GSAPort] url: "]) {
            NSURL *url=[NSURL URLWithString:[text substringFromIndex:15]];
            text=[NSString stringWithFormat:@"[GSAPort] intercepted host=%@",url.host ?: @"unknown"];
        }
        printf("LOG time=%s sender=%s %s\n",asl_get(message,ASL_KEY_TIME) ?: "?",asl_get(message,ASL_KEY_SENDER) ?: "?",text.UTF8String);
    }
    printf("Matching recent log entries: %u\n", count);
    if (results) asl_release(results);
    asl_free(query);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc>1 && !strcmp(argv[1],"methods")) {
            dlopen("/System/Library/Frameworks/Accounts.framework/Accounts",RTLD_NOW);
            Class cls=NSClassFromString(@"ACAccountStore"); unsigned count=0;
            Method *methods=class_copyMethodList(cls,&count);
            for (unsigned i=0;i<count;i++) {
                const char *name=sel_getName(method_getName(methods[i]));
                if (strstr(name,"saveAccount") || strstr(name,"verifyCredentials")) printf("METHOD %s encoding=%s\n",name,method_getTypeEncoding(methods[i]));
            }
            free(methods); return 0;
        }
        if (argc>1 && !strcmp(argv[1],"errors")) { accountErrors(); return 0; }
        if (argc>1 && !strcmp(argv[1],"logs")) { recentLogs(); return 0; }
        NSString *path=@"/Library/MobileSubstrate/DynamicLibraries/GSAPort.dylib";
        void *handle=dlopen(path.UTF8String, RTLD_NOW);
        if (!handle) { printf("LOAD FAILED: %s\n",dlerror()); return 1; }
        printf("Tweak loaded successfully\n");
        for (NSURLSessionConfiguration *config in @[[NSURLSessionConfiguration defaultSessionConfiguration],[NSURLSessionConfiguration ephemeralSessionConfiguration], [NSURLSession sharedSession].configuration]) {
            printf("Configuration %s protocols=%s\n",NSStringFromClass([config class]).UTF8String,config.protocolClasses.description.UTF8String);
        }
        for (NSString *urlString in @[@"https://gsa.apple.com/grandslam/GsService2",@"https://icloud.podpod123.com/anisette.php"]) {
            NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
            request.HTTPMethod=@"HEAD";
            NSURLResponse *response=nil; NSError *error=nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            printf("HTTPS host=%s status=%ld errorDomain=%s errorCode=%ld\n",request.URL.host.UTF8String,(long)[(NSHTTPURLResponse *)response statusCode],error.domain.UTF8String ?: "none",(long)error.code);
        }
        recentLogs();
    }
    return 0;
}
