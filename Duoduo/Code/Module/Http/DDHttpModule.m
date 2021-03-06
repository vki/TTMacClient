/************************************************************
 * @file         DDHttpModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       http模块，基于AFNetworking的实现  注：参考了Mogujie4iPhone对http的包装
 ************************************************************/

#import "DDHttpModule.h"
#import "AFHTTPClient.h"
#import "NSData+NSJSONSerialization.h"

static NSString* const URL_BASE = @"http://www.mogujie.com/";
static const uint8 REQUEST_TIMEOUT = 15;

DDHttpModule* getDDHttpModule()
{
    return (DDHttpModule*)[[DDLogic instance] queryModuleByID:MODULE_ID_HTTP];
}

@interface DDHttpModule()

-(void)requestWithUri:(NSString *)uri params:(NSDictionary *)params method:(NSString *)method success:(SuccessBlock)success failure:(FailureBlock)failure;

@end

@implementation DDHttpModule

-(id)initModule
{
    if(self = [super initModule:MODULE_ID_HTTP])
    {
        _httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:URL_BASE]];
        [_httpClient.operationQueue setMaxConcurrentOperationCount:2];
    }
    return self;
}

-(void)httpPostWithUri:(NSString *)uri params:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self requestWithUri:uri params:params method:@"POST" success:success failure:failure];
}
-(void)httpGetWithUri:(NSString *)uri params:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self requestWithUri:uri params:params method:@"GET" success:success failure:failure];
}

-(void)requestWithUri:(NSString *)uri params:(NSDictionary *)params method:(NSString *)method success:(SuccessBlock)success failure:(FailureBlock)failure
{
	NSMutableURLRequest *request = [_httpClient requestWithMethod:method path:uri parameters:params];
    [request setTimeoutInterval:REQUEST_TIMEOUT];
    
    // success block
    void (^responseSuccess)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *responseDictionary = [responseObject objectFromJSONData];
        DDHttpEntity *httpEntity = [[DDHttpEntity alloc] initWithDictionary:responseDictionary];
        //todo 设置cookies __dao=...
        
        if (1001 == httpEntity.status.code)
        {
            success(httpEntity.result);
        }
        else
        {
            httpEntity.status.userInfo = httpEntity.result;
            failure(httpEntity.status);
        }
    };
    
    // failure block
    void (^failureResponse)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        StatusEntity *status = [[StatusEntity alloc] init];
        status.code = error.code;
        failure(status);
    };
    
    [_httpClient cancelAllHTTPOperationsWithMethod:method path:uri];
    AFHTTPRequestOperation *operation = [_httpClient HTTPRequestOperationWithRequest:request success: responseSuccess failure:failureResponse ];
    [_httpClient enqueueHTTPRequestOperation:operation];
}

@end
