//
//  ViewController.swift
//  Concurrency Via BlockOperation
//
/*
 
 Copyright (c) 2017 Andrew L. Jaffee, microIT Infrastructure, LLC, and
 iosbrain.com.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 NOTE: As this code makes URL references to NASA images, if you make use of
 those URLs, you MUST abide by NASA's image guidelines pursuant to
 https://www.nasa.gov/multimedia/guidelines/index.html
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
*/

import UIKit

class ViewController: UIViewController
{
    
    // MARK: - User interface objects
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageIndexText: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var incrementCountText: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - ViewController properties
    
    var imageCounter = 0
    
    var incrementCounter = 0
    
    // NASA images used pursuant to https://www.nasa.gov/multimedia/guidelines/index.html
    let imageURLs: [String] = ["https://cdn.spacetelescope.org/archives/images/publicationjpg/heic1509a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic1501a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic1107a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/large/heic0715a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic1608a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/potw1345a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/large/heic1307a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic0817a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/opo0328a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/publicationjpg/heic0506a.jpg",
                                 "https://cdn.spacetelescope.org/archives/images/large/heic0503a.jpg"]

    // MARK: - ViewController delegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // no images have been downloaded, so there's no
        // image progress to report
        progressView.progress = 0.0
        
        // the long calculation isn't running, so we don't show
        // any activity
        activityIndicator.alpha = 0.0
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - ViewController methods: BlockOperation example code
    
    //
    // Start a long, mindless calculation IN THE BACKGROUND
    // so the UI, handled by the MAIN THREAD, doesn't freeze
    // up, and the user has a good experience
    //
    func startLongCalculation() -> Void
    {
        
        activityIndicator.alpha = 1.0
        activityIndicator.startAnimating()
        
        // create a default queue so we can put our
        // long running calculation on it for processing;
        // this queue will only have one operation on it
        let longCalculationQueue = OperationQueue()
        
        // create an operation that manages the concurrent
        // execution of one blocks; that block is a simple
        // but long-running computation (addition)
        let blockOperationForLongCalculation = BlockOperation
        {
            
            // we'll repeatedly add 1 to this value
            // one million five hundred thousand times
            var total = 0
            
            for _ in 1...10000000
            {
                total = total + 1
                print("total + 1 = \(total)")
            }
            
            // when the computation finished, we JUMP
            // ONTO THE MAIN QUEUE TO UPDATE THE UI
            OperationQueue.main.addOperation
            {
                print("FINAL total: \(total)")
                self.activityIndicator.stopAnimating()
                self.activityIndicator.alpha = 0.0
            }
            
        } // end let blockOperationForLongCalc = BlockOperation
        
        // by adding the BlockOperation to its corresponding
        // queue, it starts executing and "remains in the queue
        // until it finishes executing"
        longCalculationQueue.addOperation(blockOperationForLongCalculation)
        
    } // end func startLongCalculation()
    
    //
    // Start downloading 11 HUGE images IN THE BACKGROUND
    // so the UI, handled by the MAIN THREAD, doesn't freeze
    // up, and the user has a good experience
    //
    func startBackgroundDownload() -> Void
    {
        printDateTime()
        
        // create a default queue so we can put our
        // 11 long running image downloads on it for processing
        let imageDownloadQueue = OperationQueue()
        // "The maximum number of queued operations that can
        // execute at the same time." I set this for
        // illustrative purposes, as its probably best
        // to let iOS tune concurrency based on system
        // resources, but there may be special circumstances
        // where this could be helpful.
        imageDownloadQueue.maxConcurrentOperationCount = 20
        
        // create an operation that manages the concurrent
        // execution of 11 blocks; each block 1) starts downloading
        // a LARGE image from a specific URL and 2) when finished
        // downloading, JUMPS ONTO THE MAIN THREAD TO DISPLAY
        // THE IMAGE
        let blockOperationForImageDownloads = BlockOperation()
        
        // add 11 image download blocks to our BlockOperation
        for index in 0..<imageURLs.count
        {
            // watch how these are printed to the console
            // IMMEDIATELY; this validates backgrounding
            // and concurrency
            print("Batch 1 - Image \(index) queued for download")
            
            // add the image download blocks to our BlockOperation
            blockOperationForImageDownloads.addExecutionBlock
            {
                
                let imageURL = URL(string: self.imageURLs[index])
                let imageData = NSData(contentsOf: imageURL!)
                
                OperationQueue.main.addOperation
                {
                    print("Batch 1 - Image \(index) has downloaded")
                    self.imageCounter += 1
                    self.progressView.progress = Float(self.imageCounter) / Float(self.imageURLs.count)
                    self.imageView.image = UIImage(data: imageData! as Data)
                    self.imageIndexText.text = String(index)
                    self.view.setNeedsDisplay()
                    
                    if self.imageCounter == (self.imageURLs.count)
                    {
                        self.printDateTime()
                    }
                }
                
            } // end blockOperationForImageDownloads.addExecutionBlock
            
        } // end for index in 0..<imageURLs.count
        
        // by adding the BlockOperation, with 11 image download
        // tasks, to its corresponding queue, it starts
        // executing and "remains in the queue until it
        // finishes executing"
        imageDownloadQueue.addOperation(blockOperationForImageDownloads)
        
    } // end func startBackgroundDownload()
    
    // MARK: - ViewController methods: User interactions
    
    // Called when the button labelled "Start images downloading -
    // Batch 1" is tapped; starts download of set of LARGE images
    // in the BACKGROUND. As each image finishes downloading, it
    // is displayed in the UIImageView in this view controller.
    @IBAction func startImagesDownloadingBatch1Tapped(_ sender: Any)
    {
        startBackgroundDownload()
    }
    
    // Called when the button labelled "Start Long Calculation"
    // is tapped. Starts a "long" and simple-minded calculation
    // in the BACKGROUND. It prints output to console.
    @IBAction func startLongCalcButtonTapped(_ sender: Any)
    {
        startLongCalculation()
    }
    
    // Called when the "Increment count:" button is tapped.
    // We add one to a property every time the button is
    // tapped and display the new property value in a
    // UITextField. This PROVES that the BlockOperations
    // are running in the BACKGROUND because the button
    // and text field ALWAYS remain responsive.
    @IBAction func incrementButtonTapped(_ sender: Any)
    {
        incrementCounter = incrementCounter + 1
        incrementCountText.text = String(incrementCounter)
    }
    
    // MARK: - Utilities
    
    func printDateTime() -> Void
    {
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss:SSS"
        
        let result = formatter.string(from: date)
        
        print(result)
    }
        
} // end class ViewController

