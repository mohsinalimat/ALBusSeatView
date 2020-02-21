//
//  ALBusSeatView.swift
//  ALBusSeatView
//
//  Created by Soner Güler on 14.02.2020.
//

import UIKit

public protocol ALBusSeatViewDataSource {
    func seatView(_ seatView: ALBusSeatView, seatTypeForIndex indexPath: IndexPath) -> ALBusSeatType
    func seatView(_ seatView: ALBusSeatView, seatNumberForIndex indexPath: IndexPath) -> String
    func numberOfSections(in seatView: ALBusSeatView) -> Int
    func seatView(_ seatView: ALBusSeatView, numberOfSeatInSection section: Int) -> Int
}

public protocol ALBusSeatViewDelegate: class {
    func seatView(_ seatView: ALBusSeatView, shouldSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType) -> Bool
    func seatView(_ seatView: ALBusSeatView, shouldDeSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType) -> Bool
    func seatView(_ seatView: ALBusSeatView, didSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType, selectionType: ALSelectionType)
    func seatView(_ seatView: ALBusSeatView, deSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType)
}

// To make methods optional!
public extension ALBusSeatViewDelegate {
    func seatView(_ seatView: ALBusSeatView, shouldSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType) -> Bool { return true }
    func seatView(_ seatView: ALBusSeatView, shouldDeSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType) -> Bool { return true }
    func seatView(_ seatView: ALBusSeatView, didSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType, selectionType: ALSelectionType) {}
    func seatView(_ seatView: ALBusSeatView, deSelectAtIndex indexPath: IndexPath, seatType: ALBusSeatType) {}
}


public class ALBusSeatView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Public
    public var config = ALBusSeatViewConfig() {
        didSet {
            applyConfigs()
            setNeedsLayout()
        }
    }
    
    public var dataSource: ALBusSeatViewDataSource?
    public var delegate: ALBusSeatViewDelegate?
    
    
    // MARK: - Private
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: bounds, collectionViewLayout: layout)
        view.collectionViewLayout = layout
        view.register(ALBusSeatCell.self, forCellWithReuseIdentifier: cellID)
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        view.clipsToBounds = false
        return view
    }()
    
    private lazy var collectionBGView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var infoLabel: UILabel = {
        let lbl = UILabel()
        return lbl
    }()
    
    private let cellID = "SeatCell"
    private let headerID = "HeaderView"
    
    lazy private var tooltip: ALSelectionTooltip = {
        let tooltip = ALSelectionTooltip(frame: CGRect(x: 0, y: 0,
                                                       width: 160, height: 60))
        return tooltip
    }()
    
    
    public init(withConfig config: ALBusSeatViewConfig) {
        super.init(frame: .zero)
        self.config = config
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: - Public
    public func reload() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    
    // MARK: - Private
    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = false
        addSubview(collectionView)
        
        collectionView.backgroundView = collectionBGView
        collectionBGView.addSubview(infoLabel)
        
        applyConfigs()
        
        // Drive position setup
        if config.leftHandDrivePosition == true {
            print("leftHand active")
            let layout = ALBusLeftHandDriveLayout()
            layout.scrollDirection = .horizontal
            collectionView.collectionViewLayout = layout
        }
        
        // Bus front image setup
        collectionView.register(ALBusSeatViewHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerID)
    }
    
    private func applyConfigs() {
        infoLabel.font = config.centerHallInfoTextFont
        infoLabel.text = config.centerHallInfoText
        infoLabel.textColor = config.centerHallInfoTextColor
        tooltip.title = config.tooltipText
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        
        let colW = collectionView.frame.width
        let infoX = config.busFrontImage != nil ? config.busFrontImageWidth : 20.0
        let infoWidth = config.busFrontImage != nil ? colW - config.busFrontImageWidth : colW - 20.0
        let infoFrame = CGRect(x: infoX, y: 0, width: infoWidth, height: collectionView.frame.height)
        infoLabel.frame = infoFrame
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID,
                                                      for: indexPath) as! ALBusSeatCell
        
        guard let seatType = dataSource?.seatView(self, seatTypeForIndex: indexPath),
            let seatNumber = dataSource?.seatView(self, seatNumberForIndex: indexPath) else {
                return cell
        }
        
        cell.title = seatNumber
        cell.type = seatType
        cell.label.font = config.seatNumberFont
        cell.label.textColor = config.seatNumberColor
        
        switch seatType {
        case .empty:
            cell.coverView.backgroundColor = config.seatEmptyBGColor
        case .selected:
            cell.coverView.backgroundColor = config.seatSelectedBGColor
            if config.seatRemoveImage != nil {
                cell.removeImageView.isHidden = false
                cell.removeImageView.image = config.seatRemoveImage
            }
            cell.label.font = config.seatNumberSelectedFont
            cell.label.textColor = config.seatNumberSelectedColor
        case .soldMan:
            cell.coverView.backgroundColor = config.seatSoldManBGColor
        case .soldWoman:
            cell.coverView.backgroundColor = config.seatSoldWomanBGColor
        case .none:
            cell.coverView.backgroundColor = .clear
            cell.isUserInteractionEnabled = false
            cell.coverView.isHidden = true
        }
        
        cell.coverView.layer.borderWidth = config.seatBorderWidth
        cell.coverView.layer.borderColor = config.seatBorderColor.cgColor
        cell.coverView.layer.cornerRadius = config.seatCornerRadius
        cell.coverView.layer.shadowColor = config.seatShadowColor.cgColor
        cell.coverView.layer.shadowRadius = config.seatCornerRadius
        cell.coverView.layer.shadowOffset = config.seatShadowSize
        cell.coverView.layer.shadowOpacity = config.seatShadowOpacity
        cell.coverView.layer.masksToBounds = false
        
        return cell
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.numberOfSections(in: self) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return dataSource?.seatView(self, numberOfSeatInSection: section) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return config.marginBetweenSeats
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return config.marginBetweenSeats / 2
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                         withReuseIdentifier: headerID,
                                                                         for: indexPath) as! ALBusSeatViewHeaderView
        
        if indexPath.section == 0 && config.busFrontImage != nil {
            headerView.imageView.image = config.busFrontImage
        }  else if indexPath.section > 0 {
            headerView.imageView.image = config.floorSeperatorImage
        }
        
        return headerView
    }
    
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 && config.busFrontImage != nil {
            return CGSize(width: config.busFrontImageWidth, height: collectionView.frame.height)
        } else if section > 0 {
            return CGSize(width: config.floorSeperatorWidth, height: collectionView.frame.height)
        } else {
            return .zero
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let colH = collectionView.frame.height
        let totalMargin = config.marginBetweenSeats * 4
        
        var itemH = (colH - totalMargin - config.centerHallHeight) / 4
        let itemW = itemH
        //Center Hall
        if ((indexPath.item - 2) % 5 == 0) {
            itemH = config.centerHallHeight
        }
        
        return CGSize(width: itemW, height: itemH)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: false)
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? ALBusSeatCell else {
            return
        }
        
        if cell.type == .selected {
            delegate?.seatView(self, deSelectAtIndex: indexPath, seatType: cell.type)
            return
        }
        
        if cell.type == .empty {
            repositionScrollView(forCell: cell)
            tooltip.hide(animated: false)
            showTooltip(fromCell: cell, indexPath: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? ALBusSeatCell else {
            return false
        }
        
        if cell.type == .empty {
            return delegate?.seatView(self, shouldSelectAtIndex: indexPath, seatType: cell.type) ?? true
        } else if cell.type == .selected {
            return delegate?.seatView(self, shouldDeSelectAtIndex: indexPath, seatType: cell.type) ?? true
        }
        
        return false
    }
}

// MARK: - Tooltip
extension ALBusSeatView {
    
    
    /// Reposition the scroll view according to selected seatview to make tooltip more visible and selectable
    /// - Parameter forCell: Selected seatview to arrange scroll
    func repositionScrollView(forCell: UIView) {
        
        let mustVisibleRate: CGFloat = 0.9 // Tooltip must visible width rate ()
        let marginThreshold = (tooltip.frame.width * mustVisibleRate) / 2
        
        let point = forCell.topCenter
        let converted = forCell.convert(point, to: collectionView)
        
        let xOffset = collectionView.contentOffset.x
        let leftMarginOk = marginThreshold <= converted.x - xOffset
        let rightMarginOk = marginThreshold <= (frame.width - converted.x + xOffset)
//        debugPrint("threshold:\(marginThreshold) xOffset:\(xOffset) leftMargin: \(converted.x + abs(xOffset)) rightMargin:\(frame.width - converted.x)")
//        debugPrint("leftOK: \(leftMarginOk) - rightOK: \(rightMarginOk)")
        if !leftMarginOk {
            let currentPoint = collectionView.contentOffset
            let targetPoint = CGPoint(x: currentPoint.x - marginThreshold, y: 0)
            DispatchQueue.main.async {
                self.collectionView.setContentOffset(targetPoint, animated: true)
            }
        }
        
        if !rightMarginOk {
            let currentPoint = collectionView.contentOffset
            let targetPoint = CGPoint(x: currentPoint.x + marginThreshold, y: 0)
            DispatchQueue.main.async {
                self.collectionView.setContentOffset(targetPoint, animated: true)
            }
        }
    }
    
    
    /// Display tooltip
    /// - Parameters:
    ///   - fromCell: To arrange tooltip position for this seatView
    ///   - indexPath: To inform delegate which indexpath selected after tooltip selection
    func showTooltip(fromCell: ALBusSeatCell, indexPath: IndexPath) {
        if tooltip.isVisible {
            tooltip.hide()
            return
        }
        
        let point = fromCell.topCenter
        let converted = fromCell.convert(point, to: collectionView)
        tooltip.selectionHandler = { type in
            self.delegate?.seatView(self, didSelectAtIndex: indexPath, seatType: fromCell.type, selectionType: type)
            self.tooltip.hide()
        }
        tooltip.show(from: collectionView, origin: converted)
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let pointForTooltip = tooltip.convert(point, from: self)
        
        let hitToTooltip = tooltip.bounds.contains(pointForTooltip)
        let hitToSelf = self.bounds.contains(point)
        
        if hitToTooltip && !hitToSelf {
            return tooltip.hitTest(pointForTooltip, with: event)
        }
        
        return super.hitTest(point, with: event)
    }
}
