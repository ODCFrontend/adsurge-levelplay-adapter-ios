//
//  ISAdSurgeCustomAdapter.m
//  LevelPlayDemo
//
//  Created by 吴晗 on 2025/7/28.
//  Copyright © 2025 supersonic. All rights reserved.
//

#import "ISAdSurgeCustomAdapter.h"
#import "AdSurgeSDK/AdSurgeSDK.h"

#define ADAPTER_VERSION @"1.4.0"
#define MINI_ADAPTER_VERSION @"0"

typedef struct {
    ISAdapterErrorType errorType;
    NSInteger errorCode;
    NSString *errorMessage;
} ISAdSurgeErrorMapping;

@interface ISAdSurgeCustomAdapter ()

@property (nonatomic, assign) BOOL doNotSell;
@property (nonatomic, assign) BOOL userConsent;
@property (nonatomic, assign) BOOL isChildDirected;
@property (nonatomic, assign) BOOL isInitializationSuccess;
@end

@interface ISAdSurgeCustomRewardedVideo : ISBaseRewardedVideo <AdSurgeRewardedAdDelegate>
@property (nonatomic, strong) AdSurgeRewardedAd *rewardedAd;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> ironDelegate;
@property (nonatomic, copy) NSString *placementId;
@property (nonatomic, assign) BOOL hasGrantedReward;
@end

@interface ISAdSurgeCustomInterstitial : ISBaseInterstitial <AdSurgeInterstitialAdDelegate>
@property (nonatomic, strong) AdSurgeInterstitialAd *interstitialAd;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> ironDelegate;
@property (nonatomic, copy) NSString *placementId;
@end

@interface ISAdSurgeCustomBanner : ISBaseBanner <AdSurgeBannerAdDelegate>
@property (nonatomic, strong) AdSurgeBannerAdView *bannerAdView;
@property (nonatomic, weak) id<ISBannerAdDelegate> ironDelegate;
@property (nonatomic, copy) NSString *placementId;
@end


@implementation ISAdSurgeCustomAdapter

- (void)init:(ISAdData *)adData
    delegate:(id<ISNetworkInitializationDelegate>)delegate
{
    // 1. 合规设置
    [AdSurgePrivacyConfiguration configuration].doNotSell = @(self.doNotSell);
    [AdSurgePrivacyConfiguration configuration].ageRestrictedUser = @(self.isChildDirected);
    [AdSurgePrivacyConfiguration configuration].userConsent = @(self.userConsent);
    NSLog(@"doNotSell = %@, ageRestrictedUser = %@, userConsent = %@", [AdSurgePrivacyConfiguration configuration].isDoNotSell, [AdSurgePrivacyConfiguration configuration].isAgeRestrictedUser, [AdSurgePrivacyConfiguration configuration].hasUserConsent);
    // 2. 初始化AdSurgeSDK
    NSString *appId = adData.configuration[@"app_id"];
    if (!appId || appId.length == 0) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorMissingParams errorMessage:@"Missing app_id"];
        return;
    }
    AdSurgeSDKConfig *config = [[AdSurgeSDKConfig alloc] init];
    config.appId = appId;
    if (self.isInitializationSuccess) {
        [delegate onInitDidSucceed];
    } else {
        [[AdSurgeAdSdk shared] initializeWithConfig:config completionHandler:^(BOOL success, AdSurgeError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [delegate onInitDidSucceed];
                    self.isInitializationSuccess = YES;
                } else {
                    ISAdSurgeErrorMapping irError = [ISAdSurgeCustomAdapter toIronSourceError:error];
                    [delegate onInitDidFailWithErrorCode:irError.errorCode errorMessage:error ? error.message : @"Unknown error"];
                    NSLog(@"AdSurge init failed error:%@", error.message);
                }
            });
        }];
    }
}

- (NSString *)networkSDKVersion {
    return [AdSurgeAdSdkVersion copy];
}

- (NSString *)adapterVersion {
    return [NSString stringWithFormat:@"%@.%@", ADAPTER_VERSION , MINI_ADAPTER_VERSION];
}

- (void)setAdapterDebug:(BOOL)adapterDebug {
    // 可选：实现debug日志开关
}

+ (ISAdSurgeErrorMapping)toIronSourceError:(AdSurgeError *)adSurgeError
{
    ISAdSurgeErrorMapping mapping;
    mapping.errorMessage = adSurgeError.message ?: @"Unknown error";
    mapping.errorType = ISAdapterErrorTypeInternal;
    mapping.errorCode = ISAdapterErrorInternal;
    if (adSurgeError.code == AdSurgeErrorCodeNoFill) {
        mapping.errorType = ISAdapterErrorTypeNoFill;
        mapping.errorCode = ISAdapterErrorInternal;
    }
    return mapping;
}

- (void)setNetworkData:(id<ISAdapterNetworkData>)networkData {
    NSDictionary *allData = [networkData allData];
    self.doNotSell = [allData[@"do_not_sell"] isEqualToString:@"YES"];
    self.isChildDirected = [allData[@"is_child_directed"] isEqualToString:@"YES"];
    self.userConsent = [allData[@"has_user_consent"] isEqualToString:@"YES"];
}


@end

@implementation ISAdSurgeCustomRewardedVideo

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate
{
    self.ironDelegate = delegate;
    self.placementId = adData.configuration[@"placement_id"];
    if (!self.placementId) {
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:ISAdapterErrorMissingParams errorMessage:@"Missing placement_id"];
        return;
    }
    self.rewardedAd = [[AdSurgeRewardedAd alloc] initWithAdUnitIdentifier:self.placementId];
    self.rewardedAd.delegate = self;
    AdSurgeAdConfig *adConfig = [AdSurgeAdConfig configWithAdFormat:AdSurgeAdFormat.rewarded];
    [self.rewardedAd loadAd:adConfig];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return [self.rewardedAd isValid];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate
{
    if (![self isAdAvailableWithAdData:adData]) {
        [delegate adDidFailToShowWithErrorCode:ISAdapterErrorInternal errorMessage:@"No ad available"];
        return;
    }
    self.ironDelegate = delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd showAdFromRootViewController:viewController];
    });
}


#pragma mark - AdSurgeRewardedAdDelegate

- (void)didLoadAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidLoad];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    ISAdSurgeErrorMapping irError = [ISAdSurgeCustomAdapter toIronSourceError:error];
    [self.ironDelegate adDidFailToLoadWithErrorType:irError.errorType errorCode:irError.errorCode errorMessage:error.message];
}

- (void)didDisplayAd:(AdSurgeAd *)ad withError:(AdSurgeError *)error {
    if (error) {
        ISAdSurgeErrorMapping irError = [ISAdSurgeCustomAdapter toIronSourceError:error];
        [self.ironDelegate adDidFailToShowWithErrorCode:irError.errorCode errorMessage:error.message];
    }
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidClick];
}

- (void)didHideAd:(AdSurgeAd *)ad {
    if (self.hasGrantedReward) {
        [self.ironDelegate adRewarded];
    }
    [self.ironDelegate adDidClose];
    self.rewardedAd = nil;
}

- (void)didRewardUserForAd:(AdSurgeAd *)ad withReward:(AdSurgeReward *)reward {
    self.hasGrantedReward = YES;
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidOpen];
}

@end


@implementation ISAdSurgeCustomInterstitial

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate
{
    self.ironDelegate = delegate;
    self.placementId = adData.configuration[@"placement_id"];
    if (!self.placementId) {
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:ISAdapterErrorMissingParams errorMessage:@"Missing placement_id"];
        return;
    }
    self.interstitialAd = [[AdSurgeInterstitialAd alloc] initWithAdUnitIdentifier:self.placementId];
    self.interstitialAd.delegate = self;
    AdSurgeAdConfig *adConfig = [AdSurgeAdConfig configWithAdFormat:AdSurgeAdFormat.interstitial];
    [self.interstitialAd loadAd:adConfig];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return [self.interstitialAd isValid];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate
{
    if (![self isAdAvailableWithAdData:adData]) {
        [delegate adDidFailToShowWithErrorCode:ISAdapterErrorInternal errorMessage:@"No ad available"];
        return;
    }
    self.ironDelegate = delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showAdFromRootViewController:viewController];
    });
}



#pragma mark - AdSurgeInterstitialAdDelegate

- (void)didLoadAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidLoad];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    ISAdSurgeErrorMapping irError = [ISAdSurgeCustomAdapter toIronSourceError:error];
    [self.ironDelegate adDidFailToLoadWithErrorType:irError.errorType errorCode:irError.errorCode errorMessage:error.message];
}

- (void)didDisplayAd:(AdSurgeAd *)ad withError:(AdSurgeError *)error {
    if (error) {
        ISAdSurgeErrorMapping irError = [ISAdSurgeCustomAdapter toIronSourceError:error];
        [self.ironDelegate adDidFailToShowWithErrorCode:irError.errorCode errorMessage:error.message];
    }
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidClick];
}

- (void)didHideAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidClose];
    self.interstitialAd = nil;
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidOpen];
}

@end

@implementation ISAdSurgeCustomBanner
                                                                                                                    
- (void)loadAdWithAdData:(nonnull ISAdData *)adData
          viewController:(nonnull UIViewController *)viewController
                    size:(nonnull ISBannerSize *)size
                delegate:(nonnull id<ISBannerAdDelegate>)delegate{
    self.ironDelegate = delegate;
    self.placementId = adData.configuration[@"placement_id"];
    if (!self.placementId) {
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:ISAdapterErrorMissingParams errorMessage:@"Missing placement_id"];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = [[AdSurgeBannerAdView alloc] initWithAdUnitIdentifier:self.placementId];
        self.bannerAdView.delegate = self;
        self.bannerAdView.viewController = viewController;
        AdSurgeAdConfig *adConfig = [AdSurgeAdConfig configWithAdFormat:AdSurgeAdFormat.banner];
        [self.bannerAdView loadAd:adConfig];
    });
}

- (void)destroyAdWithAdData:(nonnull ISAdData *)adData{
    if (self.bannerAdView) {
        self.bannerAdView.delegate = nil;
        self.bannerAdView = nil;
        self.placementId = nil;
        self.ironDelegate = nil; // 清空上层代理
    }
}

#pragma mark - AdSurgeBannerAdDelegate

- (void)didLoadAd:(AdSurgeAd *)ad{
    [self.ironDelegate adDidLoadWithView:self.bannerAdView];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error{
    ISAdSurgeErrorMapping irError = [ISAdSurgeCustomAdapter toIronSourceError:error];
    [self.ironDelegate adDidFailToLoadWithErrorType:irError.errorType errorCode:irError.errorCode errorMessage:error.message];
}

- (void)didHideAd:(AdSurgeAd *)ad {
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidClick];
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [self.ironDelegate adDidOpen];
}

@end
