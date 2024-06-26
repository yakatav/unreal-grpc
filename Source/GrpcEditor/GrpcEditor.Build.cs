using UnrealBuildTool;

public class GrpcEditor : ModuleRules
{
	public GrpcEditor(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;
		
		PublicDependencyModuleNames.AddRange(
			new string[]
			{
				"Core",
				"CoreUObject",
				"Slate",
				"Engine",
				"Slate",
				"SlateCore",
				"Settings",
				"UnrealEd",
				"KismetWidgets",
				"KismetCompiler",
				"BlueprintGraph",
				"GraphEditor",
				"Kismet",
				"PropertyEditor",
				"InputCore",
				"EditorStyle",
				"Grpc"
			}
		);
	}
}