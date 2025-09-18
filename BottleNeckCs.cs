using Godot;
using System.Collections.Generic;

public partial class BottleNeckCs : Node
{
	private List<Rid> instances = new();

	public override void _Ready()
	{
		for (int i = 0; i < 250000; i++)
		{
			byte asd = 123;
			GD.Print(asd);

			var instance = RenderingServer.InstanceCreate();
			instances.Add(instance);
		}
	}
}
