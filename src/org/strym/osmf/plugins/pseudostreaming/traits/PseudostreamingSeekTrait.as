package org.strym.osmf.plugins.pseudostreaming.traits {

import flash.events.NetStatusEvent;
import flash.utils.clearInterval;
import flash.utils.setInterval;
import flash.utils.setTimeout;

import org.osmf.events.SeekEvent;
import org.osmf.media.MediaResourceBase;
import org.osmf.media.URLResource;
import org.osmf.net.NetClient;
import org.osmf.net.NetStreamCodes;
import org.osmf.traits.LoaderBase;
import org.osmf.traits.PlayState;
import org.osmf.traits.SeekTrait;
import org.osmf.traits.TimeTrait;
import org.strym.osmf.plugins.pseudostreaming.PseudostreamingNetLoader;
import org.strym.osmf.plugins.pseudostreaming.utils.StringUtils;

public class PseudostreamingSeekTrait extends SeekTrait {
	//--------------------------------------------------------------------------
	//  Constructor
	//--------------------------------------------------------------------------
	public function PseudostreamingSeekTrait(timeTrait:TimeTrait, loader:LoaderBase, resource:MediaResourceBase, nsPlayTrait:PseudoStreamingPlayTrait) {
		super(timeTrait);
		
		this._loader = loader as PseudostreamingNetLoader;
		this._resource = resource as URLResource;
		this._playTrait = nsPlayTrait;
		(this._loader.netStream).addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, 0, true);
		NetClient(this._loader.netStream.client).addHandler(NetStreamCodes.ON_META_DATA, onMetaData);
		
	}
	//--------------------------------------------------------------------------
	//  Methods
	//--------------------------------------------------------------------------
	override public function canSeekTo(time:Number):Boolean {
		return true;
	}
	
	/**
	 * Performs the seeking operation for p-streaming. In case seek withing the buffer, will do the standart ns seek.
	 * In case seek exceds the buffer boundaries, will use ns.play() routin.
	 */ 
	override protected function seekingChangeStart(newSeeking:Boolean, time:Number):void {
		if (newSeeking) {
			var maxBufferedTime:Number = pseudostreamingTimeTrait.positionOffset + pseudostreamingTimeTrait.getFragmentDuration()* 
				Number(_loader.netStream.bytesLoaded / _loader.netStream.bytesTotal);
			_isSeeking = true;
			if( isNaN( maxBufferedTime ) ) {
				maxBufferedTime = 0;
			}
			_lastSeekTime = time;
			if (time > maxBufferedTime || time <  pseudostreamingTimeTrait.positionOffset) {
				var query:String = _resource.getMetadataValue("pseudostreaming_query") as String;
				pseudostreamingTimeTrait.positionOffset = time;
				//eugene: if we in pause state, we need to pause the stream after seek
				if (query && query != "") {
					var url:String = _resource.url + query.replace("{time}", time.toString()).replace("{sessionId}", getSession().toString());
					//_loader.netStream.close();//Eugene:bug in 11.1.102.xxx versions
					_inBufferSeek = false;
					_loader.netStream.play(url);
				}
				
			}
			else {
				_inBufferSeek = true;
				_loader.netStream.seek(time);
			}
		}
	}
	
	protected function onNetStatus( event:NetStatusEvent ):void {
		switch (event.info.code) {
			case "NetStream.Seek.Complete":
				signalSeekComplete();
				break;
			case NetStreamCodes.NETSTREAM_SEEK_NOTIFY:
				if( (isAudioOnly() && _inBufferSeek) || StringUtils.isMp4( _resource.url ) ) {
					setTimeout(signalSeekComplete, 100 );
				}
				break;
			//			case NetStreamCodes.NETSTREAM_BUFFER_FULL:
			//				if( StringUtils.isMp4(_resource.url) ) {
			//					signalSeekComplete();
			//				}
			//				break;
			case NetStreamCodes.NETSTREAM_SEEK_INVALIDTIME:
				signalSeekComplete();
				break;
		}
	}
	
	protected function onMetaData( event:Object ):void {
		_flushInterval = setInterval(signalSeekComplete, 100 );
	}
	
	protected function isAudioOnly( ):Boolean {
		return _loader && _loader.netStream && _loader.netStream.info ?
			_loader.netStream.info.videoBufferLength == 0 : false; 
	}
	
	protected function signalSeekComplete( ):void {
		var time:Number = isNaN(_lastSeekTime) ? timeTrait.currentTime : _lastSeekTime;
		if( _playTrait.getState() == PlayState.PAUSED ) {
			_loader.netStream.pause();
		}
		if( _playTrait.getState() == PlayState.PLAYING) {
			setSeeking(false, time );
			dispatchSeekEnd( time );
		}
		if( _playTrait.getState() == PlayState.STOPPED ) {
			setSeeking(false, time);
			dispatchSeekEnd( time );
		}
		if( _flushInterval ) {
			clearInterval(_flushInterval);
		}
	}
	
	override protected function seekingChangeEnd(time:Number):void {
	}
	
	protected function dispatchSeekEnd( time:Number ):void {
		if( _isSeeking ) {
			dispatchEvent
			( new SeekEvent
				( SeekEvent.SEEKING_CHANGE
					, false
					, false
					, seeking
					, time
				)
			);
			_isSeeking = false;
		}
	}
	
	protected function get pseudostreamingTimeTrait():PseudostreamingTimeTrait {
		return timeTrait as PseudostreamingTimeTrait;
	}
	
	public function getSession( ):Number {
		if( isNaN(_session) ) {
			_session = new Date().time;
		}
		return _session;
	}
	//--------------------------------------------------------------------------
	//  protected variables
	//--------------------------------------------------------------------------
	protected var _loader:PseudostreamingNetLoader;
	protected var _resource:URLResource;
	protected var _session:Number;
	protected var _playTrait:PseudoStreamingPlayTrait;
	protected var _isSeeking:Boolean = false;
	protected var _lastSeekTime:Number;
	protected var _flushInterval:uint;
	protected var _inBufferSeek:Boolean = false;
}
}
