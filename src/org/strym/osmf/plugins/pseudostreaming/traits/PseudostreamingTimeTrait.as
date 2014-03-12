/**
 * Created with IntelliJ IDEA.
 * User: mexxik
 * Date: 9/14/12
 * Time: 10:14 PM
 * To change this template use File | Settings | File Templates.
 */
package org.strym.osmf.plugins.pseudostreaming.traits {
import flash.events.NetStatusEvent;
import flash.net.NetStream;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

import org.osmf.media.MediaResourceBase;
import org.osmf.media.URLResource;
import org.osmf.net.NetClient;
import org.osmf.net.NetStreamCodes;
import org.osmf.net.NetStreamUtils;
import org.osmf.traits.TimeTrait;
import org.strym.osmf.plugins.pseudostreaming.utils.StringUtils;

public class PseudostreamingTimeTrait extends TimeTrait {
	private var _duration:Number;
	private var _durationSet:Boolean = false;
	
	private var _durationOffset:Number = 0;
	private var _audioDelay:Number = 0;
	private var _netStream:NetStream;
	private var _resource:MediaResourceBase;
	private var _guardianTimeoutId:uint;
	private var _preventTimeUpdate:Boolean = false;
	
	private var _positionOffset:Number = 0;
	
	public function PseudostreamingTimeTrait(netStream:NetStream, resource:MediaResourceBase, defaultDuration:Number=NaN) {
		super();
		
		this._netStream = netStream;
		NetClient(netStream.client).addHandler(NetStreamCodes.ON_META_DATA, onMetaData);
		NetClient(netStream.client).addHandler(NetStreamCodes.ON_PLAY_STATUS, onPlayStatus);
		netStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, 0, true);
		this._resource = resource;
		
		if (isNaN(defaultDuration) == false)
		{
			setDuration(defaultDuration);
		}
		
	}
	
	private function onMetaData(value:Object):void {
		var playArgs:Object = NetStreamUtils.getPlayArgsForResource(_resource);
		
		_audioDelay = value.hasOwnProperty("audiodelay") ? value.audiodelay : 0;
		
		var subclipStartTime:Number = Math.max(0, playArgs.start);
		
		var subclipDuration:Number = playArgs.len;
		if (subclipDuration == NetStreamUtils.PLAY_LEN_ARG_ALL) {
			subclipDuration = Number.MAX_VALUE;
		}
		
		if( value['aktimeoffset'] && value['aktimeoffset'] > 0 ) {
			positionOffset = value['aktimeoffset'];
			_preventTimeUpdate = true;
			_guardianTimeoutId = setTimeout( preventTimeUpdateHandler, 1000 ); //for the case, if the video was paused and we perform seek
			//to undownloaded part.
		} else {
			if( !isNaN(duration) && duration > 0 ) {
				positionOffset = duration - value['duration'];				
			} else {
				positionOffset = 0;
			}
		}
		
		setDuration(Math.min((value.duration - _audioDelay) - subclipStartTime, subclipDuration));
	}
	
	private function preventTimeUpdateHandler( ):void {
		clearTimeout( _guardianTimeoutId );
		_preventTimeUpdate = false;
	}
	
	private function onPlayStatus(event:Object):void {
		switch(event.code) {
			case NetStreamCodes.NETSTREAM_PLAY_COMPLETE:
				signalComplete();
		}
	}
	
	private function onNetStatus(event:NetStatusEvent):void {
		switch (event.info.code) {
			case NetStreamCodes.NETSTREAM_PLAY_STOP:
				if (NetStreamUtils.isStreamingResource(_resource) == false) {
					signalComplete();
				}
				break;
			case NetStreamCodes.NETSTREAM_PLAY_UNPUBLISH_NOTIFY:
				signalComplete();
				break;
			case NetStreamCodes.NETSTREAM_PLAY_START:
			case NetStreamCodes.NETSTREAM_BUFFER_FULL:
				preventTimeUpdateHandler();
				break;
		}
	}
	
	override protected function signalComplete():void {
		if ((_netStream.time - _audioDelay) != duration) {
			_durationOffset = duration - (_netStream.time - _audioDelay);
		}
		super.signalComplete();
	}
	
	internal function get audioDelay():Number
	{
		return _audioDelay;
	}
	
	override public function get currentTime():Number {
		if( _preventTimeUpdate ) {
			//the reason is that after we received metadata for flv files, netStream.time does not reflect that update. As a result,
			//application will receive wrong current time.
			return positionOffset;
		}
		if (_durationOffset == (duration - (_netStream.time - _audioDelay))) {
			return netStreamTime - _audioDelay + _durationOffset;
		}
		else {
			return netStreamTime - _audioDelay;
		}
	}
	
	public function getFragmentDuration( ):Number {
		return super.duration;//Eugene:this._duration equals to the whole clip duration. super.duration - to the fragment duration.
	}
	
	override public function get duration():Number {
		if (_durationSet)
			return _duration
		else
			return super.duration;
	}
	
	override protected function durationChangeStart(newDuration:Number):void {
		super.durationChangeStart(newDuration);
		
		if (!_durationSet) {
			_duration = newDuration;
			
			_durationSet = true;
		}
	}
	
	public function set positionOffset(value:Number):void {
		_positionOffset = value;
	}
	
	public function get positionOffset():Number {
		return _positionOffset;
	}
	
	private function get netStreamTime( ):Number {
		var res:Number = _netStream.time;
		if( StringUtils.isMp4( (_resource as URLResource).url ) ) {
			res += _positionOffset;
		}
		if( !isNaN(_positionOffset) &&
			_positionOffset > res) {
			res = _positionOffset;
		}
		return res;
	}
}
}
