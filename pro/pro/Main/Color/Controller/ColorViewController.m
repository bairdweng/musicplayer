//
//  ColorViewController.m
//  pro
//
//  Created by xiaofan on 9/15/16.
//  Copyright © 2016 huaxia. All rights reserved.
//

#import "ColorViewController.h"
#import "MainMacos.h"
#import "BlueServerManager.h"
#import "CMDModel.h"
#import "EFCircularSlider.h"

#import <CoreBluetooth/CoreBluetooth.h>


#define COLOR_BTN_SIZE CGSizeMake(40, 40)
#define MODE_BTN_SIZE CGSizeMake(38,38)
#define SLIDER_IMAGE_SIZE CGSizeMake(90, 35)
#define SLIDER_TABLE_SIZE CGSizeMake(240, 480)

static NSString *const cellId = @"cellId";



//const static CGFloat originY = 360;
//const static CGFloat rowMargin = 20;
const static CGFloat columnMargin = 20;



@interface ColorViewController ()<UITableViewDelegate, UITableViewDataSource, BlueServerManagerDelegate> {
    NSArray<NSString *> *_backColors;
    NSArray<NSString *> *_selectedBackColors;
    NSArray<NSString *> *_btnTittles;
    NSArray<UIImage *> *_backImage;
    NSArray<UIColor *> *_colors;
    NSTimer *_timer;
    NSTimer *_timer2;
    NSData *_currentData;
    
    NSArray<CBPeripheral *> *_peripherals;
//    UIButton *_rightButton;
//    UILabel *_titleLabel;
    BOOL _on;
}
@property (nonatomic, strong) NSArray<UIButton *> *colorButtons;

@property (nonatomic, strong) UISlider *lightSlider;
//@property (nonatomic, strong) UIImageView *lightImageView;
@property (nonatomic, strong) UILabel *lightLabel;

@property (nonatomic, strong) UISlider *frequencySlider;
//@property (nonatomic, strong) UIImageView *frequenceImageView;
@property (nonatomic, strong) UILabel *frequenceLabel;

@property (nonatomic, strong) NSArray<UIButton *> *flickerButtons;
@property (nonatomic, strong) NSArray<UIButton *> *breatheButtons;

@property (nonatomic, strong) EFCircularSlider *circularSlider;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *indictorView;

@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) UIButton *powerButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, assign) int mode;

@property (nonatomic, strong) UITableView *sliderTableView;
@property (nonatomic, strong) NSArray<NSString *> *dataSource;
@property (nonatomic, strong) BlueServerManager *manager;
@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, strong) UIView *maskTableView;

@end

@implementation ColorViewController
- (instancetype)init {
    if (self = [super init]) {
        //self.title = @"color";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"adjust", nil) image:[UIImage imageNamed:@"color.png"] selectedImage:[UIImage imageNamed:@"color_selected.png"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSelf];
    [self configSubviews];
    _timer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(delayMethod) userInfo:nil repeats:NO];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
    [_timer2 invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(_currentData) {
        [_manager sendData:_currentData];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _currentData = [[CMDModel sharedInstance] getCuttentData];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    NSString *text = _dataSource[indexPath.row];
    NSArray<NSString *> *strings = [text componentsSeparatedByString:@"#"];
    if (strings && strings.count >= 1) {
        cell.textLabel.text = strings[0];
        cell.detailTextLabel.text = strings[1];
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}


static UIAlertController *alert;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self connectionBlooteeOfindex:indexPath.row];
}
-(void)connectionBlooteeOfindex:(NSInteger)index{
    _timer2 = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(delayMethod2) userInfo:nil repeats:NO];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"title", nil) message:NSLocalizedString(@"blue", nil) preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    [_manager connectPeripheral:_peripherals[index]];
}
#pragma mark - BlueServerManagerDelegate
- (void)blueServerManager:(BlueServerManager *)manager didDiscoverPeripherals:(NSArray<CBPeripheral *> *)peripherals {
    if (!(peripherals && peripherals.count)) {
        return;
    }
    NSMutableArray<NSString *> *temp = [NSMutableArray array];
    [peripherals enumerateObjectsUsingBlock:^(CBPeripheral * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //if ([obj.name isEqualToString:blueName]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:isConnectted];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSString *uuidString = obj.identifier.UUIDString;
        NSString *name = [NSString stringWithFormat:@"%@#%@",obj.name,uuidString];
        [temp addObject:name];
        //}
        
    }];
    _peripherals = peripherals;
    self.dataSource = [temp copy];
}

- (void)blueServerManager:(BlueServerManager *)manager didConnectedPeripheral:(CBPeripheral *)peripheral {
    //alert = nil;
    //NSLog(@"...");
    //[alert dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.isShow = NO;
    _titleLabel.hidden = YES;
    [_backButton setBackgroundImage:[UIImage imageNamed:@"backto"] forState:UIControlStateNormal];
    NSData *sendData = [[CMDModel sharedInstance] queryCMD];
    NSLog(@"query");
    [[BlueServerManager sharedInstance] sendQueryData:sendData];
    
}

- (void)blueServerManager:(BlueServerManager *)manager didSendQueryData:(Byte [])bytes {
    for(int i = 0; i < 6; i++) {
        NSLog(@"result: %d", bytes[i]);
    }
    
    if(bytes[0] == 1) {
        self.mode = 0;
    }
    else if (bytes[0] == 3) {
        self.mode = 1;
    }
    else if (bytes[0] == 5) {
        self.mode = 2;
    }
    else if (bytes[0] == 8) {
        self.mode = 3;
    }
    else {
        return;
    }
    
    int progess = 0;
    if(bytes[1] == 255  && bytes[3] == 0) {
        progess = bytes[2];
    }
    else if (bytes[2] == 255  && bytes[3] == 0) {
        progess = 458 - bytes[1];
    }
    else if (bytes[1] == 0  && bytes[2] == 255) {
        progess = 390 + bytes[3];
    }
    else if (bytes[1] == 0  && bytes[3] == 255) {
        progess = 900 - bytes[2];
    }
    else if (bytes[2] == 0  && bytes[3] == 255) {
        progess = 900 + bytes[1];
    }
    else if (bytes[1] == 255  && bytes[2] == 0) {
        progess = 1410 - bytes[3];
    }
    
    
    self.circularSlider.currentValue = progess / 1422.0;
    [self circularSlidervalueChanged:self.circularSlider];
   // NSLog(@"%f",self.circularSlider.currentValue);
    //self.circularSlider.currentValue = 1;
    int angle = 0;
    float value = self.circularSlider.currentValue;
    if(value > 0 && value < 0.25) {
        angle = - (int)(value * 360);
    }
    else {
        angle = (int)(360 - value * 360);
    }
    [_circularSlider setPosition:angle];
    
    
    self.lightSlider.value = bytes[4] / 100.0;
    self.frequencySlider.value = bytes[5] / 10.0;
    [[CMDModel sharedInstance] writeCMD:bytes];
}


#pragma mark - button action
- (void)clickColorsButton: (UIButton *)sender {
    NSInteger index = sender.tag - 50;
    
    [sender setBackgroundImage:[UIImage imageNamed:_selectedBackColors[index]] forState:UIControlStateNormal];
    [_colorButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (index != idx) {
            [obj setBackgroundImage:[UIImage imageNamed:_backColors[idx]] forState:UIControlStateNormal];
        }
    }];
    
    if (_mode != 0 && _mode != 2) {
        self.mode = 0;
    }
    
    UIColor *color = _colors[index];
    
    self.flickerButtons[1].backgroundColor = color;
    self.breatheButtons[1].backgroundColor = color;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sigleColorChanged" object:nil userInfo:@{@"color": color}];
    NSData *sendData = [[CMDModel sharedInstance] singleColors][index];
    [[BlueServerManager sharedInstance] sendData:sendData];
   
}

- (void)clickflickerButton: (UIButton *)sender {
    NSInteger index = sender.tag - 60;
    CMDModel *cmd = [CMDModel sharedInstance];
    NSData *sendData;
    if (index == 0) {
        return;
    }
    else if (index == 1) {
        sendData = cmd.threeBlinkCMD;
        self.mode = 0;
    }
    else if (index == 2) {
        sendData = cmd.sevenBlinkCMD;
        self.mode = 1;
    }
    [[BlueServerManager sharedInstance] sendData:sendData];
}

- (void)clickBreatheButton: (UIButton *)sender {
    NSInteger index = sender.tag - 70;
    CMDModel *cmd = [CMDModel sharedInstance];
    NSData *sendData;
    if (index == 0) {
        return;
    }
    else if (index == 1) {
        sendData = cmd.threeBreathCMD;
        self.mode = 2;
    }
    else if (index == 2) {
        sendData = cmd.sevenBreathCMD;
        self.mode = 3;
    }
    [[BlueServerManager sharedInstance] sendData:sendData];

}

- (void)circularSlidervalueChanged: (EFCircularSlider *)sender {
    static int temp;
    if (temp == sender.currentValue * 1422) {
        return;
    }
    temp = sender.currentValue * 1422;
    
    UIColor *color = [[CMDModel sharedInstance] singleColor:temp];
    self.indictorView.backgroundColor = color;
    self.flickerButtons[1].backgroundColor = color;
    self.breatheButtons[1].backgroundColor = color;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sigleColorChanged" object:nil userInfo:@{@"color": color}];
    
    NSData *sendData = [[CMDModel sharedInstance] singleColorCMD:temp];
    //NSLog(@"send data");
    [[BlueServerManager sharedInstance] sendData:sendData];
}

- (void)lightValueChanged: (UISlider *)sender {
    static int temp;
    if (temp == sender.value * 100) {
        return;
    }
    temp = sender.value * 100;
    NSData *sendData = [[CMDModel sharedInstance] brightnessCMD:(temp)];
    [[BlueServerManager sharedInstance] sendData:sendData];
}

- (void)frequencyValueChanged: (UISlider *)sender {
    static int temp;
    if (temp == sender.value * 10) {
        return;
    }
    temp = sender.value * 10;

    NSData *sendData = [[CMDModel sharedInstance] speedCMD:(temp)];
    [[BlueServerManager sharedInstance] sendData:sendData];
}

- (void)clickPowerButton: (UIButton *)sender {
    NSData *sendData;
    NSString *name;
    if (_on) {
        name = @"power_on";
        sendData = [[CMDModel sharedInstance] powerOff];
    }
    else {
        name = @"power_off";
        sendData = [[CMDModel sharedInstance] powerOn];
    }
    _on = !_on;
    [_powerButton setBackgroundImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
    [[BlueServerManager sharedInstance] sendData:sendData];
    
}


- (void)clickBackButton: (UIButton *)sender {
    UIAlertController *Action = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    for (int i = 0; i<[self.dataSource count]; i++) {
            UIAlertAction *action_1 = [UIAlertAction actionWithTitle:self.dataSource[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self connectionBlooteeOfindex:i];
            }];
            [Action addAction:action_1];
    }
    if ([self.dataSource count]==0) {
        UIAlertAction *action_1 = [UIAlertAction actionWithTitle:@"未发现可用的蓝牙设备" style:UIAlertActionStyleDefault handler:nil];
        [Action addAction:action_1];
    }
    UIAlertAction *action_2 = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDestructive handler:nil];
    [Action addAction:action_2];
    [self presentViewController:Action animated:YES completion:nil];
//    self.isShow = !_isShow;
}

#pragma mark - notification
- (void)bluDidDisconnectd: (NSNotification *)noti {
    _titleLabel.hidden = NO;
    [_backButton setBackgroundImage:[UIImage imageNamed:@"backto_off.png"] forState:UIControlStateNormal];
}
#pragma mark - gesture
- (void)tapMaskView {
    self.isShow = NO;
}
#pragma mark - private
- (void) configSelf {
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backImageView.image = [UIImage imageNamed:@"backgroud.jpg"];
    [self.view insertSubview:backImageView atIndex:0];
    _backColors = @[@"red_off.png", @"blue_off.png", @"green_off.png", @"pick_off.png", @"yellow_off.png", @"lowblue_off.png", @"white_off.png"];
    _selectedBackColors = @[@"red_on.png", @"blue_on.png", @"green_on.png", @"pick_on.png", @"yellow_on.png", @"lowblue_on.png", @"white_on.png"];
    _btnTittles = @[@"频闪",@"三色",@"七色"];
    UIColor *pick = [UIColor colorWithRed:1.0 green:0 blue:1.0 alpha:1.0];
    UIColor *lowblue = [UIColor colorWithRed:0 green:1.0 blue:1.0 alpha:1.0];
    _backImage = @[[UIImage imageNamed:@"b3.png"],[UIImage imageNamed:@"b3.png"],[UIImage imageNamed:@"mulColor.png"]];
    _colors = @[[UIColor redColor], [UIColor blueColor], [UIColor greenColor], pick, [UIColor yellowColor], lowblue, [UIColor whiteColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluDidDisconnectd:) name:@"BluServerDidDisconnected" object:nil];
}

- (void)sliderTableViewShow {
    [_manager disconnectPeripheral];
    _manager = nil;
    CGRect frame = self.sliderTableView.frame;
    frame.origin.x = 0;
    [UIView animateWithDuration:0.8 animations:^{
        _sliderTableView.frame = frame;
    } completion:^(BOOL finished) {
        [self.manager startScan];
    }];
}
- (void)sliderTableViewHidden {
    CGRect frame = self.sliderTableView.frame;
    frame.origin.x = - CGRectGetWidth(frame);
    [UIView animateWithDuration:0.8  animations:^{
        _sliderTableView.frame = frame;
        
    } completion:^(BOOL finished) {
        //
    }];
    
}

- (void) configSubviews {
    
    __weak typeof(self) weakSelf = self;
    [self.colorButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.view addSubview:obj];
    }];
    [self.view addSubview:self.lightSlider];
    [self.view addSubview:self.frequencySlider];
    [self.flickerButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.view addSubview:obj];
    }];
    [self.breatheButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.view addSubview:obj];
    }];
    [self.view addSubview:self.circularSlider];
    [self.view insertSubview:self.imageView belowSubview:_circularSlider];
    [self.view insertSubview:self.indictorView belowSubview:_circularSlider];
    
    
    
    [self.view addSubview:self.lightLabel];
    [self.view addSubview:self.frequenceLabel];
    [self.view addSubview:self.lineView];
    [self.view addSubview:self.powerButton];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.backButton];
    
//    [self.view addSubview:self.sliderTableView];
    _sliderTableView.tag = 1000;
    [self.view insertSubview:self.maskTableView belowSubview:_sliderTableView];
    
    CGRect frame = _flickerButtons[0].frame;
    frame.origin.x = CGRectGetMinX(_flickerButtons[1].frame) - CGRectGetWidth(frame) + 0.0266667 * SCREEN_WIDTH;
    _flickerButtons[0].frame = frame;
    
    frame = _breatheButtons[0].frame;
    frame.origin.x = CGRectGetMinX(_breatheButtons[1].frame) - CGRectGetWidth(frame) + 0.013333 * SCREEN_WIDTH;
    _breatheButtons[0].frame = frame;
    //self.mode = 0;
    self.isShow = YES;
    [self.manager startScan];
    
    //mas布局
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.top.equalTo(@60);
        make.width.equalTo(@60);
        make.height.equalTo(@26);
    }];
    self.backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    [self.powerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-15));
        make.width.equalTo(@60);
        make.height.equalTo(@26);
        make.centerY.equalTo(self.backButton);
    }];
    
}

#pragma mark - getter
- (NSArray<UIButton *> *)colorButtons {
    if (!_colorButtons) {
        NSMutableArray<UIButton *> *temp = [NSMutableArray array];
        CGSize size = COLOR_BTN_SIZE;
        CGFloat margin = (SCREEN_WIDTH - 2 * columnMargin - 7 * size.width) / 6;
        for (int i = 0; i < 7; i++) {
            UIButton *btn = [UIButton new];
            [btn setBackgroundImage:[UIImage imageNamed:_backColors[i]] forState:UIControlStateNormal];
            
            CGRect frame;
            frame.size = COLOR_BTN_SIZE;
            CGFloat pointY = CGRectGetMaxY(self.frequencySlider.frame) + 15;
            CGFloat pointX = columnMargin + (CGRectGetWidth(frame) + margin) * i;
            frame.origin = CGPointMake(pointX, pointY);
            btn.frame = frame;
            
            [btn addTarget:self action:@selector(clickColorsButton:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = 50 + i;
            btn.layer.cornerRadius = 8;
            btn.layer.masksToBounds = YES;
            [temp addObject:btn];
        }
        _colorButtons = [temp copy];
    }
    return _colorButtons;
}

- (UISlider *)lightSlider {
    if (!_lightSlider) {
        _lightSlider = [UISlider new];
        CGRect frame;
        frame.origin.x = CGRectGetMaxX(self.lightLabel.frame) + columnMargin;
        frame.size.width = SCREEN_WIDTH - CGRectGetMinX(frame) - columnMargin;
        frame.size.height = 20;
        frame.origin.y = CGRectGetMaxY(self.circularSlider.frame) + SCREEN_HEIGHT * 0.045;
        _lightSlider.frame = frame;
        _lightSlider.value = 1;
        [_lightSlider addTarget:self action:@selector(lightValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _lightSlider;
}

- (UISlider *)frequencySlider {
    if (!_frequencySlider) {
        _frequencySlider = [UISlider new];
        CGRect frame;
        frame.origin.x = CGRectGetMaxX(self.lightLabel.frame) + columnMargin;
        frame.size.width = SCREEN_WIDTH - CGRectGetMinX(frame) - columnMargin;
        frame.size.height = 20;
        frame.origin.y = CGRectGetMaxY(self.lightSlider.frame) + 0.045 * SCREEN_HEIGHT;
        _frequencySlider.minimumValue = 0;
        _frequencySlider.frame = frame;
        _frequencySlider.value = 0;
        [_frequencySlider addTarget:self action:@selector(frequencyValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _frequencySlider;
}

- (NSArray<UIButton *> *)flickerButtons {
    if (!_flickerButtons) {
        NSMutableArray<UIButton *> *temp = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            UIButton *btn = [UIButton new];
            
            CGRect frame;
            frame.size = MODE_BTN_SIZE;
            if(i == 0) {
                frame.size.width = 0.213333 * SCREEN_WIDTH;
            }
            CGFloat pointX = 0.048 * SCREEN_WIDTH + (CGRectGetWidth(frame) + 0.021333 * SCREEN_WIDTH) * i;
            CGFloat pointY = CGRectGetMaxY(self.colorButtons[0].frame) + columnMargin;
            frame.origin = CGPointMake(pointX, pointY);
            btn.frame = frame;
            [btn addTarget:self action:@selector(clickflickerButton:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = 60 + i;
            [temp addObject:btn];
            
            if (i == 0) {
                [btn setTitle:NSLocalizedString(@"strobe", nil) forState:UIControlStateNormal];
            }
            else if (i == 2) {
                [btn setBackgroundImage:_backImage[i] forState:UIControlStateNormal];
            }
            else {
                btn.backgroundColor = [UIColor redColor];
            }
            btn.layer.cornerRadius = 12;
            btn.layer.masksToBounds = YES;
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
        }
        _flickerButtons = [temp copy];
    }
    return _flickerButtons;
}

- (NSArray<UIButton *> *)breatheButtons {
    if (!_breatheButtons) {
        NSMutableArray<UIButton *> *temp = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            UIButton *btn = [UIButton new];
            CGRect frame;
            frame.size = MODE_BTN_SIZE;
            if(i == 0) {
                frame.size.width = 0.213333 * SCREEN_WIDTH;
            }
            CGFloat pointX = CGRectGetMaxX([self.flickerButtons lastObject].frame) + 0.138 * SCREEN_WIDTH + (CGRectGetWidth(frame) + 8) * i;
            CGFloat pointY = CGRectGetMinY(self.flickerButtons[0].frame);
            frame.origin = CGPointMake(pointX, pointY);
            btn.frame = frame;
            
            
            [btn addTarget:self action:@selector(clickBreatheButton:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = 70 + i;
            [temp addObject:btn];
            
            if (i == 0) {
                [btn setTitle:NSLocalizedString(@"plusating", nil) forState:UIControlStateNormal];
            }
            else if(i == 2){
//                UIImage *btnImage = _backImage[i];
//                CGFloat btnImageW = btnImage.size.width * 0.5;
//                CGFloat btnImageH = btnImage.size.height * 0.5;
//                UIImage *newBtnImage = [btnImage resizableImageWithCapInsets:UIEdgeInsetsMake(btnImageH, btnImageW, btnImageH, btnImageW) resizingMode:UIImageResizingModeStretch];
                [btn setBackgroundImage:_backImage[i] forState:UIControlStateNormal];
                
            }
            else {
                btn.backgroundColor = [UIColor redColor];
            }

            btn.layer.cornerRadius = 12;
            btn.layer.masksToBounds = YES;
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
        }
        _breatheButtons = [temp copy];
    }
    return _breatheButtons;
}

- (EFCircularSlider *)circularSlider {
    if (!_circularSlider) {
        CGFloat size_size = SCREEN_WIDTH * 0.58;
        CGFloat y = CGRectGetMaxY(self.backButton.frame) + 0.06 * SCREEN_HEIGHT;
        CGRect frame = CGRectMake(50, y, size_size, size_size);
         _circularSlider = [[EFCircularSlider alloc] initWithFrame:frame];
        CGPoint center = _circularSlider.center;
        center.x = self.view.center.x;
        _circularSlider.center = center;
         [_circularSlider addTarget:self action:@selector(circularSlidervalueChanged:) forControlEvents:UIControlEventValueChanged];
        _circularSlider.handleType = bigCircle;
        _circularSlider.minimumValue = 0;
        _circularSlider.maximumValue = 1;
        _circularSlider.currentValue = 0;
    }
    return _circularSlider;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        
        CGRect frame = self.circularSlider.frame;
        _imageView.frame = CGRectInset(frame, -5, -5);
        _imageView.image = [UIImage imageNamed:@"circleColor.png"];
    }
    return _imageView;
}

- (UIView *)indictorView {
    if (!_indictorView) {
        _indictorView = [UIView new];
        CGRect frame;
        CGFloat width = 0.13 * SCREEN_WIDTH;
        frame.size = CGSizeMake(width, width);
        _indictorView.frame = frame;
        _indictorView.center = self.circularSlider.center;
        _indictorView.layer.cornerRadius = 0.5 * CGRectGetHeight(frame);
        _indictorView.layer.masksToBounds = YES;
        _indictorView.backgroundColor = [UIColor redColor];
    }
    return _indictorView;
}


- (UILabel *)lightLabel {
    if (!_lightLabel) {
        _lightLabel = [UILabel new];
        CGRect frame = CGRectZero;
        frame.size = SLIDER_IMAGE_SIZE;
        frame.origin.x = 10;
        _lightLabel.frame = frame;
        CGPoint center = _lightLabel.center;
        center.y = self.lightSlider.center.y;
        _lightLabel.center = center;
        _lightLabel.textAlignment = NSTextAlignmentCenter;
        _lightLabel.font = [UIFont systemFontOfSize:14];
        _lightLabel.text = NSLocalizedString(@"bright", nil);
        _lightLabel.textColor = [UIColor whiteColor];
        _lightLabel.textAlignment = NSTextAlignmentRight;
    }
    return _lightLabel;
}

-(UILabel *)frequenceLabel {
    if (!_frequenceLabel) {
        _frequenceLabel = [UILabel new];
        CGRect frame = CGRectZero;
        frame.size = SLIDER_IMAGE_SIZE;
        frame.origin.x = 10;
        _frequenceLabel.frame = frame;
        CGPoint center = _frequenceLabel.center;
        center.y = self.frequencySlider.center.y;
        _frequenceLabel.center = center;
        _frequenceLabel.textAlignment = NSTextAlignmentCenter;
        _frequenceLabel.text = NSLocalizedString(@"frequency", nil);
        _frequenceLabel.textColor = [UIColor whiteColor];
        _frequenceLabel.font = [UIFont systemFontOfSize:14];
        _frequenceLabel.textAlignment = NSTextAlignmentRight;
    }
    return _frequenceLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        CGRect frame;
        frame.origin.x = CGRectGetMinX(self.frequenceLabel.frame);
        frame.origin.y = CGRectGetMaxY(self.colorButtons[0].frame) + 5;
        frame.size.width = SCREEN_WIDTH - 2 * CGRectGetMinX(frame);
        frame.size.height = 1.5;
        _lineView.frame = frame;
        _lineView.backgroundColor = [UIColor colorWithRed:181 / 255.0 green:181 / 255.0 blue:183 / 255.0 alpha:1.0];
        
    }
    return _lineView;
}

- (UIButton *)powerButton {
    if (!_powerButton) {
        _powerButton = [UIButton new];
        _powerButton.frame = CGRectMake(SCREEN_WIDTH - 88 -15, 54, 88, 40);
        [_powerButton addTarget:self action:@selector(clickPowerButton:) forControlEvents:UIControlEventTouchUpInside];
        [_powerButton setBackgroundImage:[UIImage imageNamed:@"power_off"] forState:UIControlStateNormal];
        _on = YES;
    }
    return _powerButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.frame = CGRectMake(0, 20, SCREEN_WIDTH, 38);
        _titleLabel.text = NSLocalizedString(@"status", nil);
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:17];
//        _titleLabel.backgroundColor = [UIColor redColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton new];
        CGRect frame = CGRectMake(15, 54, 60, 26);
        _backButton.frame = frame;
        [_backButton setBackgroundImage:[UIImage imageNamed:@"backto_off"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(clickBackButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UITableView *)sliderTableView {
    if (!_sliderTableView) {
        _sliderTableView = [UITableView new];
        CGRect frame = CGRectZero;
        frame.size = SLIDER_TABLE_SIZE;
        frame.origin.x = 0;
        frame.origin.y = CGRectGetMaxY(self.backButton.frame) + 10;
        _sliderTableView.frame = frame;
        _sliderTableView.delegate = self;
        _sliderTableView.dataSource = self;
        _sliderTableView.backgroundColor = [UIColor colorWithRed:17.0 / 255 green:18.0 / 255 blue:67.0 / 255 alpha:0.75];
    }
    return _sliderTableView;
}

- (BlueServerManager *)manager {
    if (!_manager) {
        _manager = [BlueServerManager sharedInstance];
        _manager.delegate = self;
    }
    return _manager;
}

- (UIView *)maskTableView {
    if (!_maskTableView) {
        _maskTableView = [[UIView alloc] initWithFrame:MAINSCREEN];
        _maskTableView.userInteractionEnabled = YES;
        _maskTableView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMaskView)];
        [_maskTableView addGestureRecognizer:tapGesture];
    }
    return _maskTableView;
}


#pragma mark - setter
- (void)setMode:(int)mode {
    _mode = mode;
    
    //单色闪烁
    if (mode == 0) {
        [self.flickerButtons[1] setImage:[UIImage imageNamed:@"selected.png"] forState:UIControlStateNormal];
        [self.flickerButtons[2] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.breatheButtons[1] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.breatheButtons[2] setImage:[UIImage new] forState:UIControlStateNormal];
        
    }
    //多彩闪烁
    else if (mode == 1) {
        [self.flickerButtons[1] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.flickerButtons[2] setImage:[UIImage imageNamed:@"selected.png"] forState:UIControlStateNormal];
        [self.breatheButtons[1] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.breatheButtons[2] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.colorButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setBackgroundImage:[UIImage imageNamed:_backColors[idx]] forState:UIControlStateNormal];
        }];

    }
    //单色渐变
    else if (mode == 2) {
        [self.flickerButtons[1] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.flickerButtons[2] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.breatheButtons[1] setImage:[UIImage imageNamed:@"selected.png"] forState:UIControlStateNormal];
        [self.breatheButtons[2] setImage:[UIImage new] forState:UIControlStateNormal];
    }
    //多彩渐变
    else {
        [self.flickerButtons[1] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.flickerButtons[2] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.breatheButtons[1] setImage:[UIImage new] forState:UIControlStateNormal];
        [self.breatheButtons[2] setImage:[UIImage imageNamed:@"selected.png"] forState:UIControlStateNormal];
        [self.colorButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setBackgroundImage:[UIImage imageNamed:_backColors[idx]] forState:UIControlStateNormal];
        }];

    }
    
}

- (void)setDataSource:(NSArray<NSString *> *)dataSource {
    _dataSource = dataSource;
    [self.sliderTableView reloadData];
}

- (void)setIsShow:(BOOL)isShow{
    _isShow = isShow;
    if (_isShow) {
        [self sliderTableViewShow];
        
    }
    else {
        [self sliderTableViewHidden];
    }
    _maskTableView.hidden = !_isShow;
}

#pragma mark - delayMethod
- (void)delayMethod {
    if (_dataSource && _dataSource.count > 0) {
        return;
    }
    if (_titleLabel.hidden) {
        return;
    }
    self.isShow = NO;
}

- (void)delayMethod2 {
    
    if (_titleLabel.hidden) {
        return;
    }
    self.isShow = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
    [_manager disconnectPeripheral];
    //_manager = nil;
}
@end
