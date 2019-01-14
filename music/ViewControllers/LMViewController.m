//
//  LMViewController.m
//  music
//
//  Created by Leptos on 11/26/18.
//  Copyright © 2018 Leptos. All rights reserved.
//

#import "LMViewController.h"

#import "../Models/LMInnerTubeRequest.h"
#import "../Models/LMPlaylistCellDataModel.h"
#import "../Services/LMProtobufFactory.h"
#import "../Services/LMCurrentPlayerManager.h"
#import "../Services/LMPreferencesManager.h"
#import "../Views/LMProcessedMusicDataStruct.h"

typedef NS_ENUM(NSInteger, LMViewControllerTableViewSection) {
    LMViewControllerTableViewSectionSearchBar,
    LMViewControllerTableViewSectionSearchResults,
    LMViewControllerTableViewSectionPlaylists,
};

@implementation LMViewController {
    NSArray<LMPlaylistCellDataModel *> *_playlistModels;
    NSArray<LMPlaylistCellDataModel *> *_searchModels;
    
    NSIndexPath *_currentUserSelectedPath;
    
    id <MTLCommandQueue> _metalQueue;
    id <MTLComputePipelineState> _metalPipeline;
    id <MTLBuffer> _metalBuff;
}

- (void)_processBrowseResponse:(YTIBrowseResponse *)res {
    NSMutableArray<LMPlaylistCellDataModel *> *playlists = [NSMutableArray array];
    for (YTIBrowseTabSupportedRenderers *tabRenders in res.contents.singleColumnBrowseResultsRenderer.tabsArray) {
        for (YTISectionListSupportedRenderers *sectionRenders in tabRenders.tabRenderer.content.sectionListRenderer.contentsArray) {
            for (YTIRenderer *renderer in sectionRenders.musicCarouselShelfRenderer.contentsArray) {
                YTIMusicTwoRowItemRenderer *doubleRenderer = renderer.musicTwoRowItemRenderer;
                YTICommand *endpointSplit = doubleRenderer.doubleTapNavigationEndpoint;
                
                YTIWatchPlaylistEndpoint *playlistEndpoint = endpointSplit.watchPlaylistEndpoint;
                YTIWatchEndpoint *videoEndpoint = endpointSplit.watchEndpoint;
                
                if (videoEndpoint.hasPlaylistId) {
                    playlistEndpoint.playlistId = videoEndpoint.playlistId;
                    playlistEndpoint.params = videoEndpoint.params;
                }
                
                if (playlistEndpoint.hasPlaylistId) {
                    YTIStringRun *titleRun = doubleRenderer.title.runsArray.firstObject;
                    if (titleRun.hasText) {
                        [playlists addObject:[LMPlaylistCellDataModel modelWithTitle:titleRun.text endpoint:playlistEndpoint]];
                    }
                }
            }
        }
    }
    _playlistModels = [playlists copy];
    
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        void(^tableViewUpdates)(void) = ^{
            NSIndexSet *playlistSection = [NSIndexSet indexSetWithIndex:LMViewControllerTableViewSectionPlaylists];
            NSIndexSet *searchBarSection = [NSIndexSet indexSetWithIndex:LMViewControllerTableViewSectionSearchBar];
            
            [weakself.playlistTableView reloadSections:playlistSection withRowAnimation:UITableViewRowAnimationFade];
            [weakself.playlistTableView reloadSections:searchBarSection withRowAnimation:UITableViewRowAnimationFade];
        };
        void(^tableViewFinishedUpdates)(BOOL) = ^(BOOL finished) {
            if (finished && playlists.count) {
                if ([weakself.playlistTableView numberOfRowsInSection:LMViewControllerTableViewSectionPlaylists] > 0) {
                    NSIndexPath *scrollRow = [NSIndexPath indexPathForRow:0 inSection:LMViewControllerTableViewSectionPlaylists];
                    [weakself.playlistTableView scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
            }
        };
        
        if (@available(iOS 11.0, *)) {
            [weakself.playlistTableView performBatchUpdates:tableViewUpdates completion:tableViewFinishedUpdates];
        } else {
            [weakself.playlistTableView beginUpdates];
            tableViewUpdates();
            [weakself.playlistTableView endUpdates];
            tableViewFinishedUpdates(YES);
        }
    });
}

- (void)_fetchHomeTab {
    YTIBrowseRequest *browseReq = [YTIBrowseRequest message];
    browseReq.browseId = @"FEmusic_home";
    browseReq.context.client = [LMProtobufFactory currentClientInfo];
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"browse"];
    request.responseClass = [YTIBrowseResponse class];
    request.message = browseReq;
    
    __weak typeof(self) weakself = self;
    [request completeRequestWithCompletion:^(YTIBrowseResponse *message, NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else if (message) {
            [weakself _processBrowseResponse:message];
        }
    }];
}

- (void)_processSearchResponse:(YTISearchResponse *)res {
    NSMutableArray<LMPlaylistCellDataModel *> *playlists = [NSMutableArray array];
    for (YTISectionListSupportedRenderers *listRenders in res.contents.sectionListRenderer.contentsArray) {
        for (YTIMusicShelfSupportedRenderers *shelfRenders in listRenders.musicShelfRenderer.contentsArray) {
            YTICompactListItemRenderer *compactRenderer = shelfRenders.compactListItemRenderer;
            YTICommand *endpointSplit = compactRenderer.navigationEndpoint;
            
            YTIWatchPlaylistEndpoint *playlistEndpoint = endpointSplit.watchPlaylistEndpoint;
            YTIWatchEndpoint *videoEndpoint = endpointSplit.watchEndpoint;
            
            if (videoEndpoint.hasPlaylistId) {
                playlistEndpoint.playlistId = videoEndpoint.playlistId;
                playlistEndpoint.params = videoEndpoint.params;
            }
            
            if (playlistEndpoint.hasPlaylistId) {
                YTIStringRun *titleRun = compactRenderer.title.runsArray.firstObject;
                YTIStringRun *subtitleRun = compactRenderer.subTitle.runsArray.firstObject;
                
                [playlists addObject:[LMPlaylistCellDataModel modelWithTitle:titleRun.text subTitle:subtitleRun.text endpoint:playlistEndpoint]];
            }
        }
    }
    _searchModels = [playlists copy];
    if (_currentUserSelectedPath.section == LMViewControllerTableViewSectionSearchResults) {
        _currentUserSelectedPath = nil;
    }
    
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakself.cellSearchBar.showsSearchResultsButton = YES;
        weakself.shouldShowSearchResults = YES;
        NSIndexSet *sections = [NSIndexSet indexSetWithIndex:LMViewControllerTableViewSectionSearchResults];
        [weakself.playlistTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationTop];
    });
}

- (void)_searchRequestForQuery:(NSString *)query {
    YTISearchRequest *req = [YTISearchRequest message];
    req.context.client = [LMProtobufFactory currentClientInfo];
    req.query = query;
    
    LMInnerTubeRequest *request = [LMInnerTubeRequest new];
    request.URL = [LMInnerTubeURLBuilder defaultURLForScope:@"search"];
    request.responseClass = [YTISearchResponse class];
    request.message = req;
    
    __weak typeof(self) weakself = self;
    [request completeRequestWithCompletion:^(YTISearchResponse *message, NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else if (message) {
            [weakself _processSearchResponse:message];
        }
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *query = searchBar.text;
    if (query.length) {
        [self _searchRequestForQuery:query];
    } else {
        _searchModels = nil;
        self.shouldShowSearchResults = NO;
        self.cellSearchBar.showsSearchResultsButton = NO;
    }
    [self dismissSearchCellKeyboard];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
    self.shouldShowSearchResults ^= YES; /* boolean toggle */
}

- (void)setShouldShowSearchResults:(BOOL)shouldShowSearchResults {
    _shouldShowSearchResults = shouldShowSearchResults;
    
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:LMViewControllerTableViewSectionSearchResults];
    [self.playlistTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationTop];
    if (shouldShowSearchResults && _currentUserSelectedPath) {
        if (_currentUserSelectedPath.section == LMViewControllerTableViewSectionSearchResults) {
            [self.playlistTableView selectRowAtIndexPath:_currentUserSelectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    for (UIView *initialTarget in self.cellSearchBar.subviews.firstObject.subviews) {
        if ([initialTarget isMemberOfClass:NSClassFromString(@"UISearchBarTextField")]) {
            for (UIView *potentialTarget in initialTarget.subviews) {
                if ([potentialTarget isMemberOfClass:[UIButton class]]) {
                    for (UIView *imageTarget in potentialTarget.subviews) {
                        if ([imageTarget isMemberOfClass:[UIImageView class]]) {
                            /* looking for the view that represents the "results" arrow */
                            imageTarget.transform = CGAffineTransformMakeRotation(shouldShowSearchResults ? M_PI : 0);
                        }
                    }
                }
            }
        }
    }
}

- (IBAction)dismissSearchCellKeyboard {
    [self.cellSearchBar resignFirstResponder];
}

- (UIImage *)_createCircleImageOfDiameter:(CGFloat)diameter inset:(CGFloat)inset color:(UIColor *)color {
    CGFloat dimensions = diameter + (inset * 2);
    CGRect rect = CGRectMake(inset, inset, dimensions, dimensions);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextFillEllipseInRect(context, rect);
    CGContextSaveGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _fetchHomeTab];
    
    UIColor *whiteBlueColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.98 alpha:1];
    [self.volumeView setVolumeThumbImage:[self _createCircleImageOfDiameter:18 inset:0 color:whiteBlueColor] forState:UIControlStateSelected];
    
    for (__kindof UIView *volumeSubview in self.volumeView.subviews) {
        if ([volumeSubview isMemberOfClass:NSClassFromString(@"MPButton")]) {
            volumeSubview.hidden = YES;
        } else if ([volumeSubview isKindOfClass:[UISlider class]]) {
            UISlider *__weak volumeSlider = volumeSubview; // I prefer not to retain casts
            volumeSlider.maximumTrackTintColor = [UIColor clearColor];
        }
    }
    
    self.view.tintColor = whiteBlueColor;
    
    __weak typeof(self) weakself = self;
    NSNotificationCenter *notifCenter = NSNotificationCenter.defaultCenter;
    [notifCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        weakself.shouldUpdateVisualizer = NO;
    }];
    [notifCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        weakself.shouldUpdateVisualizer = YES;
    }];
    LMCurrentPlayerManager *playerManager = LMCurrentPlayerManager.sharedManager;
    [playerManager addAudioRenderCallback:^(AudioBufferList *bufferListInOut) {
        if (weakself.shouldUpdateVisualizer) {
            // for data fluency, the same channel is always used.
            // It's safe to assume there will be at least one channel
            // Taking an average of the channels is another viable options, depending on computation time
            uintptr_t const channel = 0;
            AudioBuffer audioBuffer = bufferListInOut->mBuffers[channel];
            UInt32 audioBufferSize = audioBuffer.mDataByteSize;
            float *audioBufferData = audioBuffer.mData;
            UInt32 elements = audioBufferSize/sizeof(float);
            
            switch (LMPreferencesManager.sharedManager.visualType) {
                case LMPreferencesVisualizerTypeHistogram:
                    [weakself.equalizerView updateBuffer:audioBufferData withBufferSize:elements];
                    break;
                case LMPreferencesVisualizerTypeMetal:
                    [weakself _processAudioData:audioBufferData length:elements];
                    break;
                default:
                    break;
            }
        }
    }];
    [playerManager addMetadataChangeCallback:^(const AudioStreamBasicDescription *processingFormat) {
        weakself.equalizerView.audioService.sampleRate = processingFormat->mSampleRate;
    }];
    
    UITapGestureRecognizer *doubleTapGesture = [UITapGestureRecognizer new];
    doubleTapGesture.numberOfTapsRequired = 2;
    [doubleTapGesture addTarget:self action:@selector(_playerViewDidReceiveDoubleTap:)];
    [self.playerView addGestureRecognizer:doubleTapGesture]; /* only the video player view supports resizing */
    
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer new];
    [tapGesture addTarget:playerManager action:@selector(togglePlayPause)];
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self.visualizeHoldingView addGestureRecognizer:tapGesture];
    
    UISwipeGestureRecognizer *leftSwipe = [UISwipeGestureRecognizer new];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [leftSwipe addTarget:playerManager action:@selector(next)];
    [self.visualizeHoldingView addGestureRecognizer:leftSwipe];
    
    UISwipeGestureRecognizer *rightSwipe = [UISwipeGestureRecognizer new];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [rightSwipe addTarget:playerManager action:@selector(previous)];
    [self.visualizeHoldingView addGestureRecognizer:rightSwipe];
    
    self.equalizerView.equalizerSettings = [DPEqualizerSettings createByType:DPHistogram];
    self.equalizerView.equalizerSettings.maxBinHeight = CGRectGetHeight(self.equalizerView.bounds);
    self.equalizerView.equalizerSettings.gain = 7.5;
    
    self.equalizerView.equalizerBackgroundColor = [UIColor clearColor];
    self.equalizerView.equalizerBinColor = [UIColor colorWithRed:245/255.0 green:240/255.0 blue:255/255.0 alpha:1];
    
    self.shouldUpdateVisualizer = YES;
    self.playerView.backingPlayer = playerManager.player;
    
    id <MTLDevice> metalDevice = MTLCreateSystemDefaultDevice();
    id <MTLLibrary> defaultMetalLibrary = [metalDevice newDefaultLibrary];
    
    self.metalView.device = metalDevice;
    self.metalView.delegate = self;
    
    _metalQueue = [metalDevice newCommandQueue];
    _metalPipeline = [metalDevice newComputePipelineStateWithFunction:[defaultMetalLibrary newFunctionWithName:@"compute"] error:NULL];
    _metalBuff = [metalDevice newBufferWithLength:sizeof(struct LMProcessedMusicData) options:0];
    memset(_metalBuff.contents, 0, _metalBuff.length);
    
    [self _resetViewsForPreferenceChange];
    [notifCenter addObserver:self selector:@selector(_resetViewsForPreferenceChange) name:LMVisualTypePreferenceDidChangeNotification object:nil];
}

- (void)_processAudioData:(float *)data length:(size_t)len {
    const vDSP_Stride stride = 1;
    struct LMProcessedMusicData processed;
    
    vDSP_rmsqv (data, stride, &processed.rmesq, len);
    
    vDSP_meamgv(data, stride, &processed.meamg, len);
    vDSP_measqv(data, stride, &processed.measq, len);
    
    vDSP_maxv  (data, stride, &processed.maxvl, len);
    vDSP_maxmgv(data, stride, &processed.maxmg, len);
    
    vDSP_minv  (data, stride, &processed.minvl, len);
    vDSP_minmgv(data, stride, &processed.minmg, len);
    
    memmove(_metalBuff.contents, &processed, sizeof(processed));
}

- (void)drawInMTKView:(MTKView *)view {
    id <CAMetalDrawable> drawable = view.currentDrawable;
    id <MTLCommandBuffer> commandBuffer = [_metalQueue commandBuffer];
    id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    
    [commandEncoder setComputePipelineState:_metalPipeline];
    [commandEncoder setTexture:drawable.texture atIndex:0];
    [commandEncoder setBuffer:_metalBuff offset:0 atIndex:1];
    
    /* https://developer.apple.com/documentation/metal/calculating_threadgroup_and_grid_sizes */
    NSUInteger threadWidth = _metalPipeline.threadExecutionWidth;
    NSUInteger threadHeight = _metalPipeline.maxTotalThreadsPerThreadgroup / threadWidth;
    MTLSize threadsPerThreadgroup = MTLSizeMake(threadWidth, threadHeight, 1);
    
    if (@available(iOS 11.0, *)) {
        MTLSize threadsPerGrid = MTLSizeMake(drawable.texture.width, drawable.texture.height, 1);
        [commandEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    } else {
        MTLSize threadgroupsPerGrid = MTLSizeMake(drawable.texture.width/threadWidth, drawable.texture.height/threadHeight, 1);
        [commandEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    }
    
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (IBAction)_switchVisualType:(UISwipeGestureRecognizer *)swipe {
    LMPreferencesManager *prefs = LMPreferencesManager.sharedManager;
    LMPreferencesVisualizerType wouldBe = prefs.visualType;
    switch (swipe.direction) {
        case UISwipeGestureRecognizerDirectionUp:
            wouldBe++;
            break;
        case UISwipeGestureRecognizerDirectionDown:
            wouldBe--;
            break;
        default:
            break;
    }
    
    if (wouldBe <= LMPreferencesVisualizerTypeNone) {
        wouldBe = LMPreferencesVisualizerTypeMetal;
    } else if (wouldBe > LMPreferencesVisualizerTypeMetal) {
        wouldBe = LMPreferencesVisualizerTypeVideo;
    }
    prefs.visualType = wouldBe;
}

- (void)_resetViewsForPreferenceChange {
    switch (LMPreferencesManager.sharedManager.visualType) {
        case LMPreferencesVisualizerTypeNone:
            self.equalizerView.hidden = YES;
            self.playerView.hidden = YES;
            self.metalView.hidden = YES;
            break;
            
        case LMPreferencesVisualizerTypeVideo:
            self.equalizerView.hidden = YES;
            self.playerView.hidden = NO;
            self.metalView.hidden = YES;
            break;
            
        case LMPreferencesVisualizerTypeHistogram:
            self.equalizerView.hidden = NO;
            self.playerView.hidden = YES;
            self.metalView.hidden = YES;
            break;
            
        case LMPreferencesVisualizerTypeMetal:
            self.equalizerView.hidden = YES;
            self.playerView.hidden = YES;
            self.metalView.hidden = NO;
            break;
            
        default:
            break;
    }
}

- (IBAction)_playerViewDidReceiveDoubleTap:(UITapGestureRecognizer *)doubleTapGesture {
    if (doubleTapGesture.state == UIGestureRecognizerStateEnded) {
        if ([self.playerView.fillType isEqualToString:AVLayerVideoGravityResizeAspect]) {
            self.playerView.fillType = AVLayerVideoGravityResizeAspectFill;
        } else {
            self.playerView.fillType = AVLayerVideoGravityResizeAspect;
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self dismissSearchCellKeyboard];
    
    __weak typeof(self) weakself = self;
    [coordinator animateAlongsideTransition:NULL completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        weakself.equalizerView.equalizerSettings.maxBinHeight = CGRectGetHeight(weakself.equalizerView.frame);
        if (@available(iOS 11.0, *)) {
            [weakself setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
    }];
}

- (LMPlaylistCellDataModel *)_playlistDataModelForIndexPath:(NSIndexPath *)indexPath {
    NSArray *workingArray = nil;
    switch (indexPath.section) {
        case LMViewControllerTableViewSectionSearchResults:
            workingArray = _searchModels;
            break;
            
        case LMViewControllerTableViewSectionPlaylists:
            workingArray = _playlistModels;
            break;
            
        default:
            break;
    }
    return workingArray[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case LMViewControllerTableViewSectionSearchBar: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
            for (UISearchBar *searchCellSubview in cell.contentView.subviews) {
                if ([searchCellSubview isKindOfClass:[UISearchBar class]]) {
                    self.cellSearchBar = searchCellSubview;
                }
            }
        } break;
            
        case LMViewControllerTableViewSectionSearchResults:
        case LMViewControllerTableViewSectionPlaylists: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistCell"];
            LMPlaylistCellDataModel *playlist = [self _playlistDataModelForIndexPath:indexPath];
            cell.textLabel.text = playlist.title;
            cell.detailTextLabel.text = playlist.subTitle;
        } break;
            
        default: {
        } break;
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger ret = 0;
    switch (section) {
        case LMViewControllerTableViewSectionSearchBar: {
            ret = (BOOL)_playlistModels;
        } break;
            
        case LMViewControllerTableViewSectionSearchResults: {
            ret = (self.shouldShowSearchResults ? _searchModels.count : 0);
        } break;
            
        case LMViewControllerTableViewSectionPlaylists: {
            ret = _playlistModels.count;
        } break;
            
        default: {
        } break;
    }
    return ret;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LMPlaylistCellDataModel *playlist = [self _playlistDataModelForIndexPath:indexPath];
    LMCurrentPlayerManager.sharedManager.playlist = playlist.endpoint;
    _currentUserSelectedPath = indexPath;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; // a nice place to use Swift's "enum count" feature
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    /* I feel like this is how it should always be */
    return self.prefersStatusBarHidden;
}

@end
