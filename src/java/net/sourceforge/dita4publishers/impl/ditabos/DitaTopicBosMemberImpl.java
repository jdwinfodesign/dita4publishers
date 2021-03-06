/**
 * Copyright (c) 2009 DITA2InDesign project (dita2indesign.sourceforge.net)  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License. 
 */
package net.sourceforge.dita4publishers.impl.ditabos;

import net.sourceforge.dita4publishers.api.bos.BosException;
import net.sourceforge.dita4publishers.api.bos.BoundedObjectSet;
import net.sourceforge.dita4publishers.api.ditabos.DitaTopicBosMember;

import org.w3c.dom.Document;

/**
 * A DITA BOS Member that represents a topic.
 */ 
public class DitaTopicBosMemberImpl extends DitaBosMemberImpl implements DitaTopicBosMember {

	/**
	 * @param bos
	 * @param doc
	 * @throws BosException
	 */
	public DitaTopicBosMemberImpl(BoundedObjectSet bos, Document doc)
			throws BosException {
		super(bos, doc);
	}
	

}
