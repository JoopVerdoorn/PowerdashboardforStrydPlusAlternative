class PowerdashboardforStrydplusalternativeApp extends Toybox.Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new DatarunView() ];
    }
}


class DatarunView extends Toybox.WatchUi.DataField {
	using Toybox.WatchUi as Ui;

	//!Get device info
	var mySettings = System.getDeviceSettings();
	var screenWidth = mySettings.screenWidth;
	var screenShape = mySettings.screenShape;
	var screenHeight = mySettings.screenHeight;
	var distanceUnits = mySettings.distanceUnits;
	var is24Hour = mySettings.is24Hour;   //!boolean
	var isTouchScreen = mySettings.isTouchScreen;  //!boolean
	var numberis24Hour = 0;
	var numberisTouchScreen = 0;

    hidden var uPowerZones                  = "184:Z1:227:Z2:255:Z3:284:Z4:326:Z5:369";	
	hidden var uRequiredPower		 		= "000:999";
	var Power1 									= 0;
    var Power2 									= 0;
    var Power3 									= 0;
	var Power4 									= 0;
    var Power5 									= 0;

	var Pace1 									= 0;
    var Pace2 									= 0;
    var Pace3 									= 0;
	
	hidden var vibrateseconds = 0;
	    
    //! License serial
    hidden var umyNumber                    = 0;
    
    //! Show demoscreen
    hidden var uShowDemo					= false;

    hidden var uBacklight                   = false;
    //! true     => Force the backlight to stay on permanently
    //! false    => Use the defined backlight timeout as normal
	
	hidden var uPowerAveraging              = 1;

    hidden var uBottomLeftMetric            = 0;    
    hidden var uBottomRightMetric           = 1;    

	hidden var DisplayPower = 0;
	hidden var mCurrentPowerZone = 0;
	hidden var mfillAColour = Graphics.COLOR_LT_GRAY;
	hidden var mfillLLColour = Graphics.COLOR_LT_GRAY;
		
    hidden var mTimerRunning                = false;
    hidden var mStartStopPushed             = 0;    //! Timer value when the start/stop button was last pushed

    hidden var mLaps                        = 1;
    hidden var mLastLapPowerMarker          = 0;
	hidden var mLastLapHeartrateMarker      = 0;
    hidden var mLastLapTimeMarker           = 0;
    hidden var mLastLapStoppedTimeMarker    = 0;
    hidden var mLastLapStoppedPowerMarker   = 0;
    hidden var mLastLapStoppedHeartrateMarker    = 0;
    hidden var mLastLapDistMarker           = 0;
	hidden var mLastLapElapsedDistance      = 0;
    
    hidden var mLastLapTimerTime            = 0;
    hidden var mCurrentPower    			= 0; 
    hidden var mElapsedPower	   			= 0;
    hidden var mElapsedHeartrate   			= 0;
    hidden var mLastLapElapsedPower			= 0;
    hidden var mPowerTime					= 0;
    hidden var mCurrentHeartrate    		= 0; 
    hidden var mLastLapElapsedHeartrate		= 0;
    hidden var mHeartrateTime				= 0;
    hidden var mEH = 0;
    hidden var mLLHRM = 0;

    function initialize() {
    	 DataField.initialize();

		 var mApp = Application.getApp();
         uPowerAveraging     = mApp.getProperty("pPowerAveraging");
         uBottomLeftMetric   = mApp.getProperty("pBottomLeftMetric");
         uBottomRightMetric  = mApp.getProperty("pBottomRightMetric");
         uBacklight          = mApp.getProperty("pBacklight");
         umyNumber			 = mApp.getProperty("myNumber");
         uShowDemo			 = mApp.getProperty("pShowDemo");
         uPowerZones		 = mApp.getProperty("pPowerZones");
         uRequiredPower		 = mApp.getProperty("pRequiredPower");         
    }


    //! Calculations we need to do every second even when the data field is not visible
    function compute(info) {
		//! If enabled, switch the backlight on in order to make it stay on
        if (uBacklight) {
             Attention.backlight(true);
        }

        var mElapsedDistance    = (info.elapsedDistance != null) ? info.elapsedDistance : 0.0;
        var mLapElapsedDistance = mElapsedDistance - mLastLapDistMarker;
        if (mTimerRunning) {  //! We only do some calculations if the timer is running
            mCurrentPower    = (info.currentPower != null) ? info.currentPower : 0;
            mPowerTime		 = (info.currentPower != null) ? mPowerTime+1 : mPowerTime;
            mElapsedPower    = mElapsedPower + mCurrentPower;  
            var mLapElapsedPower = mElapsedPower - mLastLapPowerMarker;
            mCurrentHeartrate    = (info.currentHeartRate != null) ? info.currentHeartRate : 0;
            mHeartrateTime		 = (info.currentHeartRate != null) ? mHeartrateTime+1 : 0;
			if (mHeartrateTime == 0) {
				var mElapsedHeartrate = 0;
			} if (mHeartrateTime == 1) {
				mElapsedHeartrate = mCurrentHeartrate;
			} if (mHeartrateTime > 1) {				
            	mElapsedHeartrate    = mElapsedHeartrate + mCurrentHeartrate;
            }
            mEH = mElapsedHeartrate  ;
            var mLapElapsedHeartrate = mElapsedHeartrate - mLastLapHeartrateMarker;
        }
    }

    //! Store last lap quantities and set lap markers
    function onTimerLap() {
        var info = Activity.getActivityInfo();

        mLastLapTimerTime        = mPowerTime - mLastLapTimeMarker;
        mLastLapElapsedPower  = (info.currentPower != null) ? mElapsedPower - mLastLapPowerMarker : 0;
        mLastLapElapsedHeartrate = (info.currentHeartRate != null) ? mEH - mLLHRM : 0;
        mLastLapElapsedDistance  = (info.elapsedDistance != null) ? info.elapsedDistance - mLastLapDistMarker : 0;


        mLaps++;
        mLastLapDistMarker           = (info.elapsedDistance != 0) ? info.elapsedDistance : 0;
        mLastLapPowerMarker           = mElapsedPower;
        mLastLapTimeMarker            = mPowerTime;
        mLLHRM       = mEH;       
    }
    
    //! Timer transitions from stopped to running state
    function onTimerStart() {
        startStopPushed();
        mTimerRunning = true;
    }


    //! Timer transitions from running to stopped state
    function onTimerStop() {
        startStopPushed();
        mTimerRunning = false;
    }


    //! Timer transitions from paused to running state (i.e. resume from Auto Pause is triggered)
    function onTimerResume() {
        mTimerRunning = true;
    }


    //! Timer transitions from running to paused state (i.e. Auto Pause is triggered)
    function onTimerPause() {
        mTimerRunning = false;
    }


    //! Start/stop button was pushed - emulated via timer start/stop
    function startStopPushed() {
        var info = Activity.getActivityInfo();
        mStartStopPushed = (info.elapsedTime != null) ? info.elapsedTime : 0;
      }


    //! Current activity is ended
    function onTimerReset() {
        mLaps                        = 1;
        mLastLapHeartrateMarker      = 0;
        mLastLapTimeMarker           = 0;
        mLastLapTimerTime            = 0;
        mLastLapElapsedHeartrate     = 0;
        mStartStopPushed             = 0;
    }


    //! Do necessary calculations and draw fields.
    //! This will be called once a second when the data field is visible.
    function onUpdate(dc) {
       var info = Activity.getActivityInfo();
       var mColour;


        	
    	//! Check license
		if (is24Hour == false) {
        	numberis24Hour = 77;
    	} else {
    		numberis24Hour = 19;
    	}
    	if (isTouchScreen == false) {
        	numberisTouchScreen = 93;
    	} else {
    		numberisTouchScreen = 3;
    	}
		var deviceID1 = (screenWidth+screenShape)*(screenHeight+distanceUnits)-numberis24Hour-numberisTouchScreen;
		var deviceID2 = numberis24Hour+numberisTouchScreen;
		var mtest = (numberisTouchScreen+distanceUnits)*screenWidth-(screenHeight+numberis24Hour)*screenShape;
	   	   
        //! Calculate lap power
        var mLapElapsedPower = 0;
        if (info.currentPower != null) {
            mLapElapsedPower = mElapsedPower - mLastLapPowerMarker;
        }

        //! Calculate lap heartrate
        var mLapElapsedHeartrate = 0;
        if (info.currentHeartRate != null) {
            mLapElapsedHeartrate = mElapsedHeartrate - mLastLapHeartrateMarker;
        }

        //! Calculate lap distance
        var mLapElapsedDistance = 0.0;
        if (info.elapsedDistance != null) {
            mLapElapsedDistance = info.elapsedDistance - mLastLapDistMarker;
        }
        
        //! Calculate lap time and convert timers from milliseconds to seconds
        var mTimerTime      = 0;
        var mLapTimerTime   = 0;

        if (info.timerTime != null) {
            mTimerTime = mPowerTime;
            mLapTimerTime = mPowerTime - mLastLapTimeMarker;
        }
        
                //! Calculate lap speeds
        var mLapSpeed = 0.0;
        var mLastLapSpeed = 0.0;
        if (mLapTimerTime > 0 && mLapElapsedDistance > 0) {
            mLapSpeed = mLapElapsedDistance / mLapTimerTime;
        }
        if (mLastLapTimerTime > 0 && mLastLapElapsedDistance > 0) {
            mLastLapSpeed = mLastLapElapsedDistance / mLastLapTimerTime;
        }

		//!Calculate lower field metrics
		var AverageHeartrate			= (mHeartrateTime != 0) ? mElapsedHeartrate/mHeartrateTime : 0;  //! beats per minute
		var LapHeartrate				= (mLapTimerTime != 0) ? mLapElapsedHeartrate/mLapTimerTime : 0;  //! beats per minute
		var LastLapHeartrate			= (mLastLapTimerTime != 0) ? mLastLapElapsedHeartrate/mLastLapTimerTime : 0; //! beats per minute
		var AveragePower 				= (mPowerTime != 0) ? mElapsedPower/mPowerTime : 0; //! watt
		var LapPower 					= (mLapTimerTime != 0) ? Math.round(mLapElapsedPower/mLapTimerTime) : 0; //! watt
		var LastLapPower 				= (mLastLapTimerTime != 0) ? mLastLapElapsedPower/mLastLapTimerTime : 0; //! watt
		var AverageEfficiencyIndex   	= (info.averageSpeed != null && AveragePower != 0) ? info.averageSpeed*60/AveragePower : 0; //! average lap speed in meters per minute, divided by current lap Stryd power in watts
		var LapEfficiencyIndex   		= (LapPower != 0) ? mLapSpeed*60/LapPower : 0;   //! current lap speed in meters per minute, divided by current lap Stryd power in watts
		var LastLapEfficiencyIndex   	= (LastLapPower != 0) ? mLastLapSpeed*60/LastLapPower : 0;   //! last lap speed in meters per minute, divided by last lap Stryd power in watts
		var AverageEfficiencyFactor   	= (info.averageSpeed != null && AverageHeartrate != 0) ? info.averageSpeed*60/AverageHeartrate : 0; //! average speed in meters per minute,  divided by average heartrate in beats/minute
		var LapEfficiencyFactor   		= (LapHeartrate != 0) ? mLapSpeed*60/LapHeartrate : 0; //! current lap speed in meters per minute,  divided by current lap heartrate in beats/minute
		var LastLapEfficiencyFactor   	= (LastLapHeartrate != 0) ? mLastLapSpeed*60/LastLapHeartrate : 0;   //! last lap speed in meters per minute,  divided by last lap heartrate in beats/minute


        var AveragePower3sec  	 			= 0;
        var AveragePower5sec  	 			= 0;
        var currentPowertest				= 0;
        if (info.currentSpeed != null && info.currentPower != null) {
        	currentPowertest = info.currentPower; 
        }
        if (currentPowertest > 0) {
            if (currentPowertest > 0) {
            	//! Calculate average power
				if (info.currentSpeed != null) {
        			Power1								= info.currentPower; 
        		} else {
        			Power1								= 0;
				}
        		Power5 								= Power4;
        		Power4 								= Power3;
        		Power3 								= Power2;
        		Power2 								= Power1;
				AveragePower3sec= (Power1+Power2+Power3)/3;
				AveragePower5sec= (Power1+Power2+Power3+Power4+Power5)/5;
			}
 		}

        var AveragePace3sec  	 			= 0;      
        var currentPacetest				= 0;
        if (info.currentSpeed != null) {
        	currentPacetest = info.currentSpeed; 
        }
        if (currentPacetest > 0) {
            if (currentPacetest > 0) {
            	//! Calculate average Pace
				if (info.currentSpeed != null) {
        			Pace1								= info.currentSpeed; 
        		} else {
        			Pace1								= 0;
				}
        		Pace3 								= Pace2;
        		Pace2 								= Pace1;
				AveragePace3sec= (Pace1+Pace2+Pace3)/3;
			}
 		}
		
		var AEIndex0 = (info.currentPower != null and info.currentSpeed != null and info.currentPower != 0) ? 60*(info.currentSpeed)/info.currentPower : 0;
		var AEIndex3 = (AveragePower3sec != 0) ? 60*(AveragePace3sec)/AveragePower3sec : 0;
		
		if (uPowerAveraging == 0) {
			DisplayPower = (info.currentPower != null) ? info.currentPower : 0;
		} else if (uPowerAveraging == 1) {
			DisplayPower = AveragePower3sec;  
		} else if (uPowerAveraging == 2) {
			DisplayPower = AveragePower5sec;  
		} else if (uPowerAveraging == 3) {
			DisplayPower = 999;  
		} else if (uPowerAveraging == 4) {
			DisplayPower = 999;  
		} else if (uPowerAveraging == 5) {
			DisplayPower = 999;		
		}
		
        var mZ1under = uPowerZones.substring(0, 3);
        var mZ2under = uPowerZones.substring(7, 10);
        var mZ3under = uPowerZones.substring(14, 17);
        var mZ4under = uPowerZones.substring(21, 24);
        var mZ5under = uPowerZones.substring(28, 31);
        var mZ5upper = uPowerZones.substring(35, 38);          
        mZ1under = mZ1under.toNumber();
        mZ2under = mZ2under.toNumber();
        mZ3under = mZ3under.toNumber();
        mZ4under = mZ4under.toNumber();        
        mZ5under = mZ5under.toNumber();
        mZ5upper = mZ5upper.toNumber();

        var mPowerWarningunder = uRequiredPower.substring(0, 3);
        var mPowerWarningupper = uRequiredPower.substring(4, 7);
        mPowerWarningunder = mPowerWarningunder.toNumber();
        mPowerWarningupper = mPowerWarningupper.toNumber();

		//! Alert when out of predefined powerzone
		var vibrateData = [
			new Attention.VibeProfile( 100, 100 ),
			new Attention.VibeProfile(  25, 100 )
		];
		if (DisplayPower>mPowerWarningupper or DisplayPower<mPowerWarningunder) {
			 //!Toybox.Attention.playTone(TONE_LOUD_BEEP);		 
			 if (Toybox.Attention has :vibrate) {
			 	vibrateseconds = vibrateseconds + 1;	 		  			
    			if (vibrateseconds == 5) {
    				Toybox.Attention.vibrate(vibrateData);
    				vibrateseconds = 0;
    			}	
			 }
			 
		}

		var mTestPower = mCurrentPower;
		var mfillulColour = Graphics.COLOR_LT_GRAY;
		var mfillurColour = Graphics.COLOR_LT_GRAY;
		var mfillColour = Graphics.COLOR_LT_GRAY;
		var mCurrentPowerZone = 0; 
				
		if (info.currentPower != null) {
                mTestPower = DisplayPower;
                if (mTestPower >= mZ5upper) {
                    mfillColour = Graphics.COLOR_BLACK;        //! (aboveZ5)
                    mCurrentPowerZone = 6;
                } else if (mTestPower >= mZ5under) {
                    mfillColour = Graphics.COLOR_PURPLE;    	//! (Z5)
                    mCurrentPowerZone = 5;
                } else if (mTestPower >= mZ4under) {
                    mfillColour = Graphics.COLOR_RED;    	//! (Z4)
                    mCurrentPowerZone = 4;
                } else if (mTestPower >= mZ3under) {
                    mfillColour = Graphics.COLOR_GREEN;        //! (Z3)
                    mCurrentPowerZone = 3;
                } else if (mTestPower >= mZ2under) {
                    mfillColour = Graphics.COLOR_BLUE;        //! (Z2)
                    mCurrentPowerZone = 2;
                } else if (mTestPower >= mZ1under) {
                    mfillColour = Graphics.COLOR_DK_GRAY;        //! (Z1)
                    mCurrentPowerZone = 1;
                } else {
                    mfillColour = Graphics.COLOR_LT_GRAY;        //! (Z0)
                    mCurrentPowerZone = 0;
                }
                mfillulColour = mfillColour;                 
        }		

		if (info.currentPower != null) {
                mTestPower = LapPower;
                if (mTestPower >= mZ5upper) {
                    mfillColour = Graphics.COLOR_BLACK;        //! (aboveZ5)
                } else if (mTestPower >= mZ5under) {
                    mfillColour = Graphics.COLOR_PURPLE;    	//! (Z5)
                } else if (mTestPower >= mZ4under) {
                    mfillColour = Graphics.COLOR_RED;    	//! (Z4)
                } else if (mTestPower >= mZ3under) {
                    mfillColour = Graphics.COLOR_GREEN;        //! (Z3)
                } else if (mTestPower >= mZ2under) {
                    mfillColour = Graphics.COLOR_BLUE;        //! (Z2)
                } else if (mTestPower >= mZ1under) {
                    mfillColour = Graphics.COLOR_DK_GRAY;        //! (Z1)
                } else {
                    mfillColour = Graphics.COLOR_LT_GRAY;        //! (Z0)
                }
                mfillurColour = mfillColour;                 
        }

              
		//!Determine whether demofield should be displayed
        if (uShowDemo == false) {
        	if (umyNumber != mtest && mTimerTime > 900)  {
        		uShowDemo = true;        		
        	}
        }

//!===============================Device specific code hereunder==============================================================
        
     if (uShowDemo == true ) {       
		//! Show demofield
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
		if (umyNumber == mtest) {
			dc.drawText(107, 110, Graphics.FONT_XTINY, "Registered !!", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(80, 150, Graphics.FONT_XTINY, "License code: ", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(150, 150, Graphics.FONT_XTINY, mtest, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		} else {
      		dc.drawText(100, 20, Graphics.FONT_XTINY, "License needed !!", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      		dc.drawText(100, 40, Graphics.FONT_XTINY, "Run is recorded though", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(50, 85, Graphics.FONT_MEDIUM, "ID 1: ", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(137, 78, Graphics.FONT_NUMBER_MEDIUM, deviceID1, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(50, 132, Graphics.FONT_MEDIUM, "ID 2: " , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(137, 125, Graphics.FONT_NUMBER_MEDIUM, deviceID2, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      	}
		
      } else {
        //! Show datafield instead of demofield       
        //! Coordinates of colour indicators
		var xful = 0;
		var yful = 0;
		var wful = 102;
		var hful = 27;
		
		var xfur = 104;
		var yfur = 0;
		var wfur = 101;
		var hfur = 27;

		var xfbl = 0;
		var yfbl = 121;
		var wfbl = 102;
		var hfbl = 27;
		
		var xfbr = 104;
		var yfbr = 121;
		var wfbr = 101;
		var hfbr = 27;
		
		//! Draw separator lines
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(0,   74,  205, 74);
        dc.drawLine(103, 0,  103, 148);

        //! Set text colour and font
 	    var Garminfont2 = Graphics.FONT_NUMBER_HOT;
	    var Garminfont3 = Graphics.FONT_LARGE;
	    
        //!
        //! Coordinates of labels and metrics
        //!
		var xul = 53;
		var yul = 51;
		var xtul = 55;
		var ytul = 14;
		
		var xur = 155;
		var yur = 51;
		var xtur = 155;
		var ytur = 14;
		
		var xbl = 53;
		var ybl = 98;
		var xtbl = 52;
		var ytbl = 136;
		
		var xbr = 155;
		var ybr = 98;
		var xtbr = 155;
		var ytbr = 136;
		
		var zero = 0;

//!===============================Device specific code hereabove==============================================================
		
		//! Drawing upper colour indicators
        mColour = Graphics.COLOR_LT_GRAY; 
        dc.setColor(mfillulColour, Graphics.COLOR_TRANSPARENT);		
		dc.fillRectangle(xful, yful, wful, hful);
        dc.setColor(mfillurColour, Graphics.COLOR_TRANSPARENT);		
        dc.fillRectangle(xfur, yfur, wfur, hfur);
				
        //! Top row left: Power 
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xul, yul, Garminfont2, DisplayPower, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtul, ytul, Garminfont3,  "Power", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Top row right: Lap power
        dc.drawText(xur, yur, Garminfont2, LapPower, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtur, ytur, Garminfont3,  "Lap P", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
		var fieldValue = 0;
		var fieldLabel = "Error";
		var fieldformat = "0decimal";
        //! Bottom left: Average power is default
        if (uBottomLeftMetric == 0) {
            fieldValue = AveragePower;
            fieldLabel = "Average";
            fieldformat = "0decimal";
        } else if (uBottomLeftMetric == 1) {
            fieldValue = LastLapPower;
            fieldLabel = "L-1 P";
            fieldformat = "0decimal";
        } else if (uBottomLeftMetric == 2) {
            fieldValue = AverageEfficiencyIndex;
            fieldLabel = "AE index";
            fieldformat = "2decimal";
        } else if (uBottomLeftMetric == 3) {
            fieldValue = LapEfficiencyIndex;
            fieldLabel = "LE index";
            fieldformat = "2decimal";
        } else if (uBottomLeftMetric == 4) {
            fieldValue = LastLapEfficiencyIndex;
            fieldLabel = "L-1E ind";
            fieldformat = "2decimal";
        } else if (uBottomLeftMetric == 5) {
            fieldValue = AverageEfficiencyFactor;
            fieldLabel = "AE factor";
            fieldformat = "2decimal";
        } else if (uBottomLeftMetric == 6) {
            fieldValue = LapEfficiencyFactor;
            fieldLabel = "LE factor";
            fieldformat = "2decimal";          
        } else if (uBottomLeftMetric == 7) {
            fieldValue = AEIndex0;
            fieldLabel = "AEI 0s";
            fieldformat = "2decimal";
        } else if (uBottomLeftMetric == 8) {
            fieldValue = AEIndex3;
            fieldLabel = "AEI 3s";
            fieldformat = "2decimal";
		}
		
		//! Drawing lower left colour indicator
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);        
        dc.fillRectangle(xfbl, yfbl, wfbl, hfbl);        
        
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if (fieldformat.equals("0decimal" ) == true ) {
           dc.drawText(xbl, ybl, Garminfont2, fieldValue.format("%d"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("1decimal" ) == true ) {
        	dc.drawText(xbl, ybl, Garminfont2, fieldValue.format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("2decimal" ) == true ) {
        	dc.drawText(xbl, ybl, Garminfont2, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(xtbl, ytbl, Garminfont3, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Bottom right: Last lap power is default
        fieldLabel = "Error";
        if (uBottomRightMetric == 0) {
            fieldValue = AveragePower;
            fieldLabel = "Average";
            fieldformat = "0decimal";
        } else if (uBottomRightMetric == 1) {
            fieldValue = LastLapPower;
            fieldLabel = "L-1 P";
            fieldformat = "0decimal";
        } else if (uBottomRightMetric == 2) {
            fieldValue = AverageEfficiencyIndex;
            fieldLabel = "AE index";
            fieldformat = "2decimal";
        } else if (uBottomRightMetric == 3) {
            fieldValue = LapEfficiencyIndex;
            fieldLabel = "LE index";
            fieldformat = "2decimal";
        } else if (uBottomRightMetric == 4) {
            fieldValue = LastLapEfficiencyIndex;
            fieldLabel = "L-1E ind";
            fieldformat = "2decimal";
        } else if (uBottomRightMetric == 5) {
            fieldValue = AverageEfficiencyFactor;
            fieldLabel = "AE factor";
            fieldformat = "2decimal";
        } else if (uBottomRightMetric == 6) {
            fieldValue = LapEfficiencyFactor;
            fieldLabel = "LE factor";
            fieldformat = "2decimal";          
        } else if (uBottomRightMetric == 7) {
            fieldValue = AEIndex0;
            fieldLabel = "AEI 0s";
            fieldformat = "2decimal";
        } else if (uBottomRightMetric == 8) {
            fieldValue = AEIndex3;
            fieldLabel = "AEI 3s";
            fieldformat = "2decimal";
		}

		//! Drawing lower right colour indicator        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xfbr, yfbr, wfbr, hfbr);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if (fieldformat.equals("0decimal" ) == true ) {
           dc.drawText(xbr, ybr, Garminfont2, fieldValue.format("%d"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);        
        } else if ( fieldformat.equals("1decimal" ) == true ) {
        	dc.drawText(xbr, ybr, Garminfont2, fieldValue.format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("2decimal" ) == true ) {
        	dc.drawText(xbr, ybr, Garminfont2, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
		dc.drawText(xtbr, ytbr, Garminfont3, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

	   } 
		
	}
}
