package org.strym.osmf.plugins.pseudostreaming {

import flash.net.NetStream;

import org.osmf.elements.VideoElement;
import org.osmf.media.MediaResourceBase;
import org.osmf.net.NetLoader;
import org.osmf.net.NetStreamLoadTrait;
import org.osmf.net.NetStreamPlayTrait;
import org.osmf.traits.MediaTraitBase;
import org.osmf.traits.MediaTraitType;
import org.osmf.traits.TimeTrait;
import org.strym.osmf.plugins.pseudostreaming.traits.PseudoStreamingPlayTrait;
import org.strym.osmf.plugins.pseudostreaming.traits.PseudostreamingLoadTrait;
import org.strym.osmf.plugins.pseudostreaming.traits.PseudostreamingSeekTrait;
import org.strym.osmf.plugins.pseudostreaming.traits.PseudostreamingTimeTrait;

public class PseudostreamingVideoElement extends VideoElement {

	public function PseudostreamingVideoElement(resource:MediaResourceBase = null, loader:NetLoader = null) {
		super(resource, loader);
		
		smoothing = true;
	}
	
	public function get fragmentStartTime():Number {
		return (getTrait( MediaTraitType.TIME) as PseudostreamingTimeTrait).positionOffset;
	}
	
	public function get fragmentDuration():Number {
		return (getTrait( MediaTraitType.TIME) as PseudostreamingTimeTrait).getFragmentDuration();
	}
	
	public function getNsBytesTotal( ):Number {
		var ns:NetStream = getNs();
		if( ns ) {
			return ns.bytesTotal;
		}
		return NaN;
	}
	
	public function getNsBytesLoaded( ):Number {
		var ns:NetStream = getNs();
		if( ns ) {
			return ns.bytesLoaded;
		}
		return NaN;
	}
	
	/**
	 * Overrides the default behaviour. Will use it's own Traits for p-streaming.
	 */ 
	override protected function addTrait(type:String, instance:MediaTraitBase):void {
		var trait:MediaTraitBase = instance;
		
		if (type == MediaTraitType.PLAY ) {
			var playTrait:NetStreamPlayTrait = instance as NetStreamPlayTrait;
			trait = new PseudoStreamingPlayTrait( playTrait.getNetStream(), playTrait.getResource(), playTrait.getReconnectStreams(), playTrait.getNetConnection() );
		}
		
		if (type == MediaTraitType.TIME) {
			trait = new PseudostreamingTimeTrait((loader as PseudostreamingNetLoader).netStream, resource);
		}
		else if (type == MediaTraitType.SEEK) {
			var timeTrait:TimeTrait = null;
			var nsPlayTrait:PseudoStreamingPlayTrait;
			
			if (hasTrait(MediaTraitType.TIME)) {
				timeTrait = getTrait(MediaTraitType.TIME) as TimeTrait;
			}
			
			if(hasTrait(MediaTraitType.PLAY)) {
				nsPlayTrait = getTrait(MediaTraitType.PLAY) as PseudoStreamingPlayTrait;
			}
			
			if (timeTrait) {
				trait = new PseudostreamingSeekTrait(timeTrait, loader, resource, nsPlayTrait);
			}
		}
		
		super.addTrait(type, trait);
	}
	
	protected function getNs( ):NetStream {
		if( loader is PseudostreamingNetLoader ) {
			return (loader as PseudostreamingNetLoader).netStream;
		}
		return null;
	}
}
}
