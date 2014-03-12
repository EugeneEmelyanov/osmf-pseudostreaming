package org.strym.osmf.plugins.pseudostreaming.traits
{
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.sendToURL;
	
	import org.osmf.media.MediaResourceBase;
	import org.osmf.net.NetStreamPlayTrait;
	import org.osmf.traits.PlayState;
	
	public class PseudoStreamingPlayTrait extends NetStreamPlayTrait
	{
		public function PseudoStreamingPlayTrait(netStream:NetStream, resource:MediaResourceBase, reconnectStreams:Boolean, netConnection:NetConnection)
		{
			super(netStream, resource, reconnectStreams, netConnection );
		}
	}
}