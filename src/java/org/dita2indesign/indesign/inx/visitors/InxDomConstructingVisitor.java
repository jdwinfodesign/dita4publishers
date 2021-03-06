/**
 * Copyright 2009 DITA2InDesign project (dita2indesign.sourceforge.net)  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.  n nLicensed under the Apache License, Version 2.0 (the "License"); nyou may not use this file except in compliance with the License. nYou may obtain a copy of the License at n n   http://www.apache.org/licenses/LICENSE-2.0 n nUnless required by applicable law or agreed to in writing, software ndistributed under the License is distributed on an "AS IS" BASIS, nWITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. nSee the License for the specific language governing permissions and nlimitations under the License.   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License. 
 */
package org.dita2indesign.indesign.inx.visitors;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;

import org.apache.log4j.Logger;
import org.dita2indesign.indesign.inx.model.ContourOption;
import org.dita2indesign.indesign.inx.model.DocumentPreferences;
import org.dita2indesign.indesign.inx.model.Image;
import org.dita2indesign.indesign.inx.model.InDesignComponent;
import org.dita2indesign.indesign.inx.model.InDesignDocument;
import org.dita2indesign.indesign.inx.model.InDesignGeometryHavingObject;
import org.dita2indesign.indesign.inx.model.InDesignObject;
import org.dita2indesign.indesign.inx.model.InDesignRectangleContainingObject;
import org.dita2indesign.indesign.inx.model.InxHelper;
import org.dita2indesign.indesign.inx.model.InxObjectRef;
import org.dita2indesign.indesign.inx.model.InxValue;
import org.dita2indesign.indesign.inx.model.Link;
import org.dita2indesign.indesign.inx.model.MasterSpread;
import org.dita2indesign.indesign.inx.model.Page;
import org.dita2indesign.indesign.inx.model.Rectangle;
import org.dita2indesign.indesign.inx.model.Spread;
import org.dita2indesign.indesign.inx.model.Story;
import org.dita2indesign.indesign.inx.model.TextContents;
import org.dita2indesign.indesign.inx.model.TextFrame;
import org.dita2indesign.indesign.inx.model.TextStyleRange;
import org.dita2indesign.indesign.inx.model.TextWrapPreferences;
import org.dita2indesign.util.DataUtil;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.ProcessingInstruction;


/**
 * Visitor that constructs a new INX XML DOM from an InDesign document.
 */
public class InxDomConstructingVisitor implements InDesignDocumentVisitor {
	
	Logger logger = Logger.getLogger(this.getClass());

	private Document resultDom;

	private Node currentParentNode;

	/**
	 * @param systemId System ID for the result document
	 */
	public InxDomConstructingVisitor() {
		resultDom = DataUtil.constructNonValidatingDocumentBuilder().newDocument();
	}

	public Document getResultDom() {
		return this.resultDom;
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.InDesignDocument)
	 */
	public void visitDocument(InDesignDocument doc) throws Exception {
		logger.debug("visitDocument(): Calling accept() on doc " + doc);
		doc.accept(this);
		logger.debug("visitDocument(): Returning");
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.InDesignDocument)
	 */
	public void visit(InDesignDocument doc) throws Exception {
		logger.debug("visit(): Starting...");
		doc.updatePropertyMap();
		if (doc.getDataSource() != null) {
			logger.debug("visit(): Document has a data source...");
			Element docElem = doc.getDataSource().getDocumentElement();
			if (docElem == null)
				throw new Exception("Input InDesign document has data source document but no document element");
			// This is copied straight from a CS3-created INX file. Not sure which parts are essential.
			// <?aid style="33" type="document" DOMVersion="5.0" readerVersion="4.0" featureSet="257" product="5.0(662)" ?>
			ProcessingInstruction pi = resultDom.createProcessingInstruction("aid", 
					"style=\"33\" type=\"document\" DOMVersion=\"5.0\" readerVersion=\"4.0\" featureSet=\"257\" product=\"5.0(662)\"");
			Node newDocElem = null;
			resultDom.appendChild(pi);
			newDocElem = DataUtil.importNodeAsChild(resultDom, docElem);
			// Now visit the result of the document components:
			this.currentParentNode = newDocElem;
			logger.debug("visit(InDesignDocument): iterating over children:");
			// It appears that stories (cflo) must be output after any spreads
			for (InDesignComponent comp : doc.getChildren()) {
				if (logger.isDebugEnabled()) {
					String dsName = comp.getInxTagName();
					dsName = "<" + dsName + ">";
					logger.debug("visit(InDesignDocument): child=" + comp.getClass().getSimpleName() + ", " + dsName);
				}
				if (!(comp instanceof Story)) {
					comp.accept(this);
				}				
			}
			Iterator<Story> storyIter = doc.getStoryIterator();
			while (storyIter.hasNext()) {
				Story story = storyIter.next();
				if (logger.isDebugEnabled()) {
					String dsName = story.getInxTagName();
					dsName = "<" + dsName + ">";
					logger.debug("visit(InDesignDocument): child=" + story.getClass().getSimpleName() + ", " + dsName);
				}
				story.accept(this);
			}
			
			
		} else {
			logger.debug("visit(): Document does not have a data source.");
			
		}
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.InDesignComponent)
	 */
	public void visit(InDesignComponent comp) throws Exception {
		logger.debug("visit(InDesignComponent): Starting...");
			Element myElement = processInDesignComponent(comp);
			currentParentNode = myElement.getParentNode();
	}

	private Element processInDesignComponent(InDesignComponent comp) throws Exception {
		comp.updatePropertyMap(); // Give the object a chance to update it's property map
		String tagName = comp.getInxTagName();
		if (tagName == null) {
			throw new Exception("No INX tagname value for component " + comp);
		}
		Element myElement = this.currentParentNode.getOwnerDocument().createElement(tagName);
		this.currentParentNode.appendChild(myElement);
		for (String propName : comp.getPropertyMap().keySet()) {
			InxValue value = comp.getValueObject(propName);
			myElement.setAttribute(propName, value.toEncodedString());
		}
		Node origParent = currentParentNode;
		currentParentNode = myElement;
		for (InDesignComponent childComp : comp.getChildren()) {
			childComp.accept(this);
		}
		currentParentNode = origParent;
		return myElement;
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.InDesignObject)
	 */
	public void visit(InDesignObject obj) throws Exception {
			Element myElement = processInDesignObject(obj);
			currentParentNode = myElement.getParentNode();
	}

	private Element processInDesignObject(InDesignObject obj)
			throws Exception {
		Element myElement = processInDesignComponent(obj);
		setSelfAttribute(obj, myElement);
		setLabelAttribute(obj, myElement);
		setPNameAttribute(obj, myElement);
		return myElement;
	}

	/**
	 * @param obj
	 * @param myElement
	 * @throws Exception 
	 */
	private void setPNameAttribute(InDesignComponent obj, Element myElement) throws Exception {
		String pName = obj.getPName();
		if (pName != null) {
			myElement.setAttribute(InDesignDocument.PROP_PNAM, InxHelper.encodeString(pName));
		}
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.TextFrame)
	 */
	public void visit(TextFrame frame)  throws Exception {
		Element elem = processInDesignObject(frame);
		setGeometryAttribute(frame, elem);
		currentParentNode = elem.getParentNode();
	}

	/**
	 * @param rect
	 * @param elem
	 */
	private void setGeometryAttribute(InDesignRectangleContainingObject rect, Element elem) {
		String geoValue = InxHelper.encodeGeometry(rect.getGeometry());
		elem.setAttribute(InDesignDocument.PROP_IGEO, geoValue);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.Rectangle)
	 */
	public void visit(Rectangle comp) throws Exception {
		visit((InDesignRectangleContainingObject)comp);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.Spread)
	 */
	public void visit(Spread spread) throws Exception {
		logger.debug("visit(Spread): Starting...");
		Element elem = processInDesignObject(spread);

		currentParentNode = elem.getParentNode();
		
	}

	/**
	 * @param obj
	 * @param elem
	 */
	private void setLabelAttribute(InDesignComponent obj, Element elem) {
		int lblcnt = 0;
		// FIXME: This encoding should really be handled more generically by the InxHelper
		//        class.
		StringBuilder labelValue = new StringBuilder("");
		if (obj.getLabels().size() > 0) {
			for (Entry<String, String> entry : obj.getLabels().entrySet()) {
				labelValue.append("x_2_")
				  .append("c_")
				  .append(entry.getKey())
				  .append("_c_")
				  .append(entry.getValue().replace("_", "~sep~"));
				lblcnt++;
			}
			String labelStr = "x_" + Integer.toHexString(lblcnt) + "_" + labelValue.toString();
			elem.setAttribute(InDesignDocument.PROP_PTAG, labelStr);
		}
		
	}

	/**
	 * Construct a read/write object reference value.
	 * @param comp
	 * @return
	 */
	protected String constructObjectReference(InDesignObject comp) {
		return constructObjectReference(comp, false);
	}

	protected String constructObjectReference(InDesignObject comp, boolean readOnly) {
		String dataType = "o_"; // R/W object ref.
		if (readOnly)
			dataType = "ro_";
		if (comp == null) {
			return "o_n";
		} else {
			return dataType + comp.getId();
		}
	}

	protected void setSelfAttribute(InDesignObject obj, Element elem) {
		elem.setAttribute("Self", "rc_" + obj.getId());
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.MasterSpread)
	 */
	public void visit(MasterSpread spread) throws Exception {
		visit((Spread)spread);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.Page)
	 */
	public void visit(Page page)  throws Exception {
		Element elem = processInDesignObject(page);
		elem.setAttribute("pmas", constructObjectReference(page.getMasterSpread())); 
		List<InxValue> overrideList = new ArrayList<InxValue>();
		for (TextFrame frame : page.getAllFrames()) {
			TextFrame master = frame.getMasterFrame();
			if (master != null) {
				overrideList.add(new InxObjectRef(master.getId()));
				overrideList.add(new InxObjectRef(frame.getId()));				
			}			
		}
		if (overrideList.size() > 0) {
			String propValue = InxHelper.encodeValueList(overrideList);
			elem.setAttribute(InDesignDocument.PROP_OVRL, propValue);
		}
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.Story)
	 */
	public void visit(Story story)  throws Exception {
		Element elem = processInDesignObject(story);
		currentParentNode = elem.getParentNode();
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.TextRun)
	 */
	public void visit(TextStyleRange comp)  throws Exception {
		Element elem = processInDesignComponent(comp);
		currentParentNode = elem.getParentNode();
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.DocumentPreferences)
	 */
	public void visit(DocumentPreferences prefs)  throws Exception {
		visit((InDesignComponent)prefs);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.Link)
	 */
	public void visit(Link link) throws Exception {
		logger.debug("visit(Link): Starting...");
		Element elem = currentParentNode.getOwnerDocument().createElement(InDesignDocument.CLNK_TAGNAME);
		setLinkInfoAttribute(link, elem);
		elem = processInDesignObject(link);
		currentParentNode = elem.getParentNode();
		
	}

	private void setLinkInfoAttribute(Link link, Element elem) {
		/*
		 * These are the values in the LnkI attribute.
		 * See section "p_LinkInfo" in the Working With INX File Format doc
		 * from the CS3 SDK documentation.
		 * 
	Link name:                c link_test_01-Article 2This.incx
	Link volume (Mac only):   c Macintosh HD
	DirID:                    l 786c08
	Class ID (invariant):     l 8c01
	Link type:                k InCopyInterchange
	File type:                l 49437835
	MacOS file name:          c Macintosh HD:Users:ekimber:workspace:rsi-inx-util:test:resources:link_test_01 Assignments:content:link_test_01-Article 2This.incx
	File size:                L 0~3c40
	File timestamp:           T 2008-12-04T12:17:30
	Link state:               l 0
	IsLinkNeeded:             b f
	linkEdited:               b f
		 */
		StringBuilder linkInfo = new StringBuilder("x_c_");
		// FIXME: doing this here rather than using InxHelper because there's no obvious way to make
		//        this processing more convenient or general. Need to think about this more.
		linkInfo.append(InxHelper.encodeString(link.getWindowsFileName()))
		.append("_")
		.append(InxHelper.encodeString(link.getVolume()))
		.append("_")
		.append(InxHelper.encode32BitLong(link.getDirId()))
		.append("_")
		.append(InxHelper.encode32BitLong(link.getClassId()))
		.append("_")
		.append(InxHelper.encodeEnumeration(link.getLinkType()))
		.append("_")
		.append(InxHelper.encode32BitLong(link.getFileType()))
		.append("_")
		.append(InxHelper.encodeString(link.getMacFileName()))
		.append("_")
		.append(InxHelper.encode64BitLong(link.getFileSize()))
		.append("_")
		.append(InxHelper.encodeTime(link.getDate()))
		.append("_")
		.append(InxHelper.encode32BitLong(link.getEditingState()))
		.append("_")
		.append(InxHelper.encodeBoolean(link.isLinkNeeded()))
		.append("_")
		.append(InxHelper.encodeBoolean(link.isLinkEdited()))
		;
		elem.setAttribute(InDesignDocument.PROP_LNKI, linkInfo.toString());
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.visitors.TextContents)
	 */
	public void visit(TextContents pcnt) throws Exception {
		
		Element pcntElem = this.currentParentNode.getOwnerDocument().createElement("pcnt");
		
		
		NodeList contents = pcnt.getContents();
		for (int i = 0; i < contents.getLength(); i++) {
			Node node = contents.item(i).cloneNode(false);
			pcntElem.getOwnerDocument().adoptNode(node);
			pcntElem.appendChild(node);
		}
		this.currentParentNode.appendChild(pcntElem);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.Image)
	 */
	public void visit(Image image) throws Exception {
		logger.debug("visit(Image): Starting...");
		visit((InDesignGeometryHavingObject)image);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.ContourOption)
	 */
	public void visit(ContourOption contourOption) throws Exception {
		visit((InDesignComponent)contourOption);
	}

	/* (non-Javadoc)
	 * @see org.dita2indesign.indesign.inx.visitors.InDesignDocumentVisitor#visit(org.dita2indesign.indesign.inx.model.TextWrapPreferences)
	 */
	public void visit(TextWrapPreferences textWrapPrefs) throws Exception {
		visit((InDesignComponent)textWrapPrefs);
		
	}

}
