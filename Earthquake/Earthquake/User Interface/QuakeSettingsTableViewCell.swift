//
//  QuakeSettingsTableViewCell.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import UIKit

class QuakeSettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var interiorView: UIView!
    @IBOutlet weak var historicalRangeLabel: UILabel!
    @IBOutlet weak var historicalRangeSlider: UISlider!
    @IBOutlet weak var minMagnitudeSwitch: UISwitch!
    @IBOutlet weak var minMagnitudeLabel: UILabel!
    @IBOutlet weak var minMagnitudeSlider: UISlider!
    @IBOutlet weak var refreshButton: UIButton!

    @IBAction func historicalRangeSliderChanged(_ sender: Any) {
        // We've denominated the slider in hours, so convert to seconds
        // for a time interval.
        let seconds = TimeInterval(historicalRangeSlider.value * 3600)
        coordinator?.setHistoricalRange(seconds)
        updateHistoricalRangeLabel()
    }

    /// Annotates the range label with the selected number of hours.
    func updateHistoricalRangeLabel() {
        let hours = Int(historicalRangeSlider.value.rounded(.down))
        historicalRangeLabel.text = "Historical Range (\(hours) hours)"
    }

    @IBAction func minMagnitudeSliderChanged(_ sender: Any) {
        let magnitude = Double(minMagnitudeSlider.value)
        coordinator?.setMinimummMagnitude(magnitude)
        updateMinMagnitudeLabel()
    }

    /// Annotates the magnitude label with the selected minimum.
    func updateMinMagnitudeLabel() {
        let value = Double(minMagnitudeSlider.value).to1dp
        minMagnitudeLabel.text = "Minimum Magnitude (\(value))"
    }
    
    @IBAction func minMagnitudeSwitchChanged(_ sender: Any) {
        coordinator?.setUseMinimumMagnitude(minMagnitudeSwitch.isOn)
        updateMinMagnitudeSlider()
    }

    /// Styles the magnitude slider to clarify that it is unavailable if
    /// minimum magnitude is not being used.
    func updateMinMagnitudeSlider() {
        let usingMagnitude = minMagnitudeSwitch.isOn

        minMagnitudeSlider.isUserInteractionEnabled = usingMagnitude
        minMagnitudeSlider.tintColor = usingMagnitude ? nil : .lightGray
        minMagnitudeSlider.alpha = usingMagnitude ? 1.0 : 0.2
    }

    @IBAction func tappedRefresh(_ sender: Any) {
        coordinator?.refreshQuakeList()
    }

    weak var coordinator: QuakeCoordinator?

    func setRefreshEnabled(_ enabled: Bool) {
        refreshButton.isUserInteractionEnabled = enabled
        refreshButton.tintColor = enabled ? nil : .lightGray
    }

    func configure() {
        interiorView.layer.cornerRadius = 3.0
        interiorView.layer.borderWidth = 2.0
        interiorView.layer.borderColor = UIColor(named: "BorderColour")?.cgColor

        guard
            let historicalRange = coordinator?.getHistoricalRange(),
            let useMinMagnitude = coordinator?.isUsingMinimumMagnitude(),
            let minMagnitude = coordinator?.getMinimumMagnitude()
        else {
            return
        }

        // The coordinator keeps the historical change in seconds, so
        // convert to hours for the interface.
        let hours = historicalRange / 3600.0
        historicalRangeSlider.value = Float(hours)
        updateHistoricalRangeLabel()

        minMagnitudeSwitch.isOn = useMinMagnitude
        updateMinMagnitudeSlider()

        minMagnitudeSlider.value = Float(minMagnitude)
        updateMinMagnitudeLabel()

        if let refreshEnabled = coordinator?.isRefreshEnabled {
            refreshButton.isUserInteractionEnabled = refreshEnabled
            refreshButton.tintColor = refreshEnabled ? nil : .lightGray
        }
    }
    
}
