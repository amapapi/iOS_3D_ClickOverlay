//
//  ClickOverlayViewController.m
//  officialDemo2D
//
//  Created by yi chen on 14-5-7.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "ClickOverlayViewController.h"

#import "SelectableOverlay.h"

#import "Utility.h"

@interface ClickOverlayViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;

@property (nonatomic, strong) NSMutableArray *overlays;

@end


@implementation ClickOverlayViewController

#pragma mark - MAMapViewDelegate

- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[SelectableOverlay class]])
    {
        SelectableOverlay * selectableOverlay = (SelectableOverlay *)overlay;
        id<MAOverlay> actualOverlay = selectableOverlay.overlay;
        if ([actualOverlay isKindOfClass:[MACircle class]])
        {
            MACircleView *circleView = [[MACircleView alloc] initWithCircle:actualOverlay];
            
            circleView.lineWidth   = 4.f;
            circleView.strokeColor = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
            circleView.fillColor   = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
            
            return circleView;
        }
        else if ([actualOverlay isKindOfClass:[MAPolygon class]])
        {
            MAPolygonView *polygonView = [[MAPolygonView alloc] initWithPolygon:actualOverlay];
            polygonView.lineWidth   = 4.f;
            polygonView.strokeColor = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
            polygonView.fillColor   = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
            
            return polygonView;
        }
        else if ([actualOverlay isKindOfClass:[MAPolyline class]])
        {
            MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:actualOverlay];
            
            polylineView.lineWidth   = 4.f;
            polylineView.strokeColor = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
            
            return polylineView;
        }
    }

    return nil;
}

#pragma mark - Utility

/*!
 计算当前ZoomLevel下屏幕上一点对应的MapPoints点数
 @return mapPoints点数
 */
- (double)mapPointsPerPointInViewAtCurrentZoomLevel
{
    return [self.mapView metersPerPointForCurrentZoomLevel] * MAMapPointsPerMeterAtLatitude(self.mapView.centerCoordinate.latitude);
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

#pragma mark - Handle Gestures

- (void)handleSingleTap:(UITapGestureRecognizer *)theSingleTap
{
    CGPoint touchLocation = [theSingleTap locationInView:self.mapView];
    
    NSLog(@"touchLocation (%f %f) zoomLevel %f", touchLocation.x, touchLocation.y, self.mapView.zoomLevel);
    
    /* 逆序遍历overlay判断单击点是否在overlay响应区域内. */
    [self.mapView.overlays enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<MAOverlay> overlay, NSUInteger idx, BOOL *stop)
    {
        if ([overlay isKindOfClass:[SelectableOverlay class]])
        {
            SelectableOverlay *selectableOverlay = overlay;
            
            /* 获取overlay对应的view. */
            MAOverlayPathView * View = (MAOverlayPathView *)[self.mapView viewForOverlay:selectableOverlay];
            
            /* 把屏幕坐标转换为MAMap坐标. */
            MAMapPoint mapPoint = MAMapPointForCoordinate([self.mapView convertPoint:touchLocation toCoordinateFromView:self.mapView]);
            /* overlay的线宽换算到MAMap坐标系的宽度. */
            double mapPointDistance = View.lineWidth * [self mapPointsPerPointInViewAtCurrentZoomLevel];

            /* 判断是否选中了overlay. */
            if (isOverlayWithLineWidthContainsPoint(selectableOverlay.overlay, mapPointDistance, mapPoint) )
            {
                /* 设置选中状态. */
                selectableOverlay.selected = !selectableOverlay.isSelected;
                
                /* 修改view选中颜色. */
                View.fillColor   = selectableOverlay.isSelected? selectableOverlay.selectedColor:selectableOverlay.regularColor;
                View.strokeColor = selectableOverlay.isSelected? selectableOverlay.selectedColor:selectableOverlay.regularColor;
                
                /* 修改overlay覆盖的顺序. */
                [self.mapView exchangeOverlayAtIndex:idx withOverlayAtIndex:self.mapView.overlays.count - 1];
                
                [View setNeedsDisplay];
                
                *stop = YES;
            }
            
        }
        
    }];

}

#pragma mark - Initialization

- (void)setupGestures
{
    // 需要额外添加一个双击手势，以避免当执行mapView的双击动作时响应两次单击手势。
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
    self.doubleTap.delegate = self;
    self.doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:self.doubleTap];
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    self.singleTap.delegate = self;
    [self.view addGestureRecognizer:self.singleTap];
}

- (void)initOverlays
{
    self.overlays = [NSMutableArray array];
    
    /* Circle. */
    MACircle *circle = [MACircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(39.981892, 116.338255) radius:2000];
    SelectableOverlay * selectableCircle = [[SelectableOverlay alloc] initWithOverlay:circle];
    [self.overlays addObject:selectableCircle];

    /* Polygon. */
    CLLocationCoordinate2D coordinates[4];
    coordinates[0].latitude = 39.981892;
    coordinates[0].longitude = 116.293413;
    
    coordinates[1].latitude = 39.987600;
    coordinates[1].longitude = 116.391842;
    
    coordinates[2].latitude = 39.933187;
    coordinates[2].longitude = 116.417932;
    
    coordinates[3].latitude = 39.904653;
    coordinates[3].longitude = 116.338255;
    MAPolygon *polygon = [MAPolygon polygonWithCoordinates:coordinates count:4];
    SelectableOverlay * selectablePolygon = [[SelectableOverlay alloc] initWithOverlay:polygon];
    [self.overlays addObject:selectablePolygon];
    
    /* Polyline1. */
    CLLocationCoordinate2D polylineCoords[5];
    polylineCoords[0].latitude = 39.925539;
    polylineCoords[0].longitude = 116.549037;
    
    polylineCoords[1].latitude = 39.855539;
    polylineCoords[1].longitude = 116.549037;

    polylineCoords[2].latitude = 39.855539;
    polylineCoords[2].longitude = 116.430285;
    
    polylineCoords[3].latitude = 39.795479;
    polylineCoords[3].longitude = 116.430859;
    
    polylineCoords[4].latitude = 39.795479;
    polylineCoords[4].longitude = 116.396786;
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:polylineCoords count:5];
    SelectableOverlay * selectablePolyline = [[SelectableOverlay alloc] initWithOverlay:polyline];
    [self.overlays addObject:selectablePolyline];
    
    /* Polyline2. */
    CLLocationCoordinate2D polylineCoords2[4];
    polylineCoords2[0].latitude = 39.925539;
    polylineCoords2[0].longitude = 116.549037;
    
    polylineCoords2[1].latitude = 39.925539;
    polylineCoords2[1].longitude = 116.460859;
    
    polylineCoords2[2].latitude = 39.795479;
    polylineCoords2[2].longitude = 116.460859;
    
    polylineCoords2[3].latitude = 39.795479;
    polylineCoords2[3].longitude = 116.396786;
    MAPolyline *polyline2 = [MAPolyline polylineWithCoordinates:polylineCoords2 count:4];
    SelectableOverlay * selectablePolyline2 = [[SelectableOverlay alloc] initWithOverlay:polyline2];
    selectablePolyline2.selected = YES;
    [self.overlays addObject:selectablePolyline2];
    
}

#pragma mark - Life Cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initOverlays];
        [self setTitle:@"Click Overlay"];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGestures];

    [self.mapView addOverlays:self.overlays];
    
}

@end
