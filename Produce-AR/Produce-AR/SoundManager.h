//
//  SoundManager.h
//  Produce-AR
//
//  Created by Ankush Gola on 10/6/17.
//  Copyright © 2017 Ankush Gola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Sound keys (for snare, hat, kick)
#define kKickKey @"KICK"
#define kSnareKey @"SNARE"
#define kHatKey @"HAT"

// Sound clip names in assets folder
#define kSangoKick1 @"Sango_Kick_3"
#define kSangoKick2 @"Sango_Kick_4"
#define kSangoKick3 @"Sango_Kick_7"

#define kSangoHat1 @"Sango_Kick_1"
#define kSangoHat2 @"Sango_Kick_2"

#define kSangoSnare @"Sango_Lite_Snare_1"

// TODO: one AVAudioPlayer for each Key note file
@interface SoundManager : NSObject

- (instancetype)initWithDefaults;

- (void)updateSound:(NSString *)soundKey
          toNewFile:(NSString *)clipName;

- (void)updateKeys:(NSString *)keysClipName;

- (void)playSound:(NSString *)soundKey;
- (void)playKeysWithNotes:(NSArray *)notes;

@end
