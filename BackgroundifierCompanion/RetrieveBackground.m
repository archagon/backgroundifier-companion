//
//  RetrieveBackground.m
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

#import <sqlite3.h>
#import "RetrieveBackground.h"

@implementation RetrieveBackground

//https://stackoverflow.com/a/301573/89812
//https://stackoverflow.com/questions/6768684/osx-lion-applescript-how-to-get-current-space-from-mission-control
//https://github.com/w0lfschild/macOS_headers/blob/master/macOS/CoreServices/Dock/1849.14/Dock.Spaces.h
//http://ianyh.com/blog/identifying-spaces-in-mac-os-x/
//
//NSWorkspaceActiveSpaceDidChangeNotification
//defaults read com.apple.spaces
//
//SELECT display_uuid,space_uuid,value
//FROM preferences
//JOIN data ON preferences.data_id=data.ROWID
//JOIN pictures ON preferences.picture_id=pictures.ROWID
//JOIN displays ON pictures.display_id=displays.ROWID
//JOIN spaces ON pictures.space_id=spaces.ROWID ;

+(NSString*) backgroundForDesktop:(NSUInteger)desktop screen:(NSUInteger)screen
{
    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* dbPath = [dirs[0] stringByAppendingPathComponent:@"Dock/desktoppicture.db"];
    
    sqlite3* db;
    
    if (sqlite3_open_v2(dbPath.UTF8String, &db, SQLITE_OPEN_READONLY, NULL) == SQLITE_OK)
    {
        sqlite3_stmt* statement;
        const char* sql = "SELECT * FROM data";
        
        if (sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK)
        {
            NSString* file;
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                file = @((char*)sqlite3_column_text(statement, 0));
                //printf("%s/%s\n", @"".UTF8String, file.UTF8String);
            }
            
            printf("Final: %s/%s\n\n", @"".UTF8String, file.UTF8String);
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(db);
    }
    
    [RetrieveBackground activeSpaceIdentifier];
    
    return @"";
}

//http://ianyh.com/blog/identifying-spaces-in-mac-os-x/
+(NSString*) activeSpaceIdentifier
{
    [[NSUserDefaults standardUserDefaults] removeSuiteNamed:@"com.apple.spaces"];
    [[NSUserDefaults standardUserDefaults] addSuiteNamed:@"com.apple.spaces"];
    
    NSArray* spaceProperties = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"SpacesDisplayConfiguration"][@"Space Properties"];
    
    NSMutableArray* spaceIdentifiers = [NSMutableArray array];
    NSMutableDictionary* spaceIdentifiersByWindowNumber = [NSMutableDictionary dictionary];
    
    for (NSDictionary* spaceDictionary in spaceProperties)
    {
        [spaceIdentifiers addObject:spaceDictionary[@"name"]];
        
        NSArray* windows = spaceDictionary[@"windows"];
        
        for (NSNumber* window in windows)
        {
            if (spaceIdentifiersByWindowNumber[window])
            {
                spaceIdentifiersByWindowNumber[window] = [spaceIdentifiersByWindowNumber[window] arrayByAddingObject:spaceDictionary[@"name"]];
            }
            else
            {
                spaceIdentifiersByWindowNumber[window] = @[ spaceDictionary[@"name"] ];
            }
        }
    }
    
    NSString* activeSpaceIdentifier = nil;
    
    CFArrayRef windowDescriptions = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    {
        for (NSDictionary* dictionary in (__bridge NSArray*)windowDescriptions)
        {
            NSNumber* windowNumber = dictionary[(__bridge NSString*)kCGWindowNumber];
            NSArray* spaceIdentifiers = spaceIdentifiersByWindowNumber[windowNumber];
            
            if (spaceIdentifiers.count == 1)
            {
                activeSpaceIdentifier = spaceIdentifiers[0];
                break;
            }
        }
    }
    CFRelease(windowDescriptions);
    
    NSUInteger index = [spaceIdentifiers indexOfObject:activeSpaceIdentifier];
    NSLog(@"Index of space: %d", index);
    
    return activeSpaceIdentifier;
}

@end
