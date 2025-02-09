//
//  BAbstractUploadHandler.m
//  Pods
//
//  Created by Benjamin Smiley-andrews on 12/11/2016.
//
//

#import "BAbstractUploadHandler.h"
#import <ChatSDK/Core.h>

@implementation BAbstractUploadHandler

-(RXPromise *) uploadImage:(UIImage *)image {
    
    // Upload the images:
    return [RXPromise all:@[
        [self uploadFile:UIImagePNGRepresentation(image) withName:@"image.jpg" mimeType:@"image/jpeg"],
    ]].thenOnMain(^id(NSArray * results) {
        NSMutableDictionary * urls = [NSMutableDictionary new];
        for (NSDictionary * result in results) {
            if ([result[bFileName] hasSuffix:@"image.jpg"]) {
                urls[bImagePath] = [result[bFilePath] absoluteString];
            }
        }
        return urls;
    }, Nil);
}

-(RXPromise *) uploadFile:(NSData *)file withName: (NSString *) name mimeType: (NSString *) mimeType {
  assert(NO);
  NSError * error = [NSError errorWithDomain:@"Error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Method forbidden"}];
  return [RXPromise rejectWithReason:error];
}

// By default we assume that we don't need to upload the
// avatar.
-(BOOL) shouldUploadAvatar {
    return NO;
}

@end
