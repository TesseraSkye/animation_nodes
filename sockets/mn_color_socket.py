import bpy
from bpy.types import NodeTree, Node, NodeSocket
from mn_utils import *
from mn_execution import nodePropertyChanged

class ColorSocket(NodeSocket):
	bl_idname = "ColorSocket"
	bl_label = "Color Socket"
	dataType = "Color"
	allowedInputTypes = ["Float", "Integer"]
	
	color = bpy.props.FloatVectorProperty(default = [0.5, 0.5, 0.5], subtype = "COLOR", soft_min = 0.0, soft_max = 1.0, update = nodePropertyChanged)
	
	def draw(self, context, layout, node, text):
		if not self.is_output and not isSocketLinked(self):
			layout.prop(self, "color", text = text)
		else:
			layout.label(text)
			
	def draw_color(self, context, node):
		return (0.8, 0.8, 0.2, 1)
		
	def getValue(self):
		return self.color
		
	def setStoreableValue(self, data):
		self.color = data
	def getStoreableValue(self):
		return self.color
		
# register
################################
	
def register():
	bpy.utils.register_module(__name__)

def unregister():
	bpy.utils.unregister_module(__name__)