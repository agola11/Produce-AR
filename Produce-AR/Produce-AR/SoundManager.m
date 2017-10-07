//
//  SoundManager.m
//  Produce-AR
//
//  Created by Ankush Gola on 10/6/17.
//  Copyright © 2017 Ankush Gola. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "SoundManager.h"

static NSString *const kKeysKey = @"KEYS";

@implementation SoundManager
{
    // used to hold instances of the AVAudioPlayers (need one for each file to play simultaneously)
    NSMutableDictionary<NSString *, AVAudioPlayer *> *_audioPlayers;
    NSString *_kickName;
    NSString *_snareName;
    NSString *_hatName;
    NSString *_keysName;
}

- (instancetype)initWithDefaults
{
    if (self = [super init]) {
        // Default files
        _kickName = @"Sango_Kick_4";
        _snareName = @"Sango_Lite_Snare_1";
        _hatName = @"Sango_Hat_1";
        
        _audioPlayers = [NSMutableDictionary new];
        _audioPlayers[kKickKey] = [self getPlayerForAssetName:_kickName];
        _audioPlayers[kSnareKey] = [self getPlayerForAssetName:_snareName];
        _audioPlayers[kHatKey] = [self getPlayerForAssetName:_hatName];
        
        // TODO: create three players for each key note, add them all to the dictionary with key kKeysKey
    }
    return self;
}

- (void)playSound:(NSString *)soundKey
{
    AVAudioPlayer *player = _audioPlayers[soundKey];
    if ([player isPlaying]) {
        // restart player
        [player stop];
        [player setCurrentTime:0.0];
    }
    [player play];
}

- (void)updateSound:(NSString *)soundKey
          toNewFile:(NSString *)clipName
{
    _audioPlayers[soundKey] = [self getPlayerForAssetName:clipName];
}

// TODO: fill this out, this play all the players that match the notes
- (void)playKeysWithNotes:(NSArray *)notes
{
    
}

// TODO: update all keys with this clip
- (void)updateKeys:(NSString *)keysClipName
{
    
}


- (AVAudioPlayer *)getPlayerForAssetName:(NSString *)assetName
{
    NSDataAsset *asset = [[NSDataAsset alloc] initWithName:assetName];
    
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:[asset data]
                                                   fileTypeHint:AVFileTypeWAVE
                                                          error:nil];
    return player;
}

@end

